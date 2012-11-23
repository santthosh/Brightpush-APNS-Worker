import 'lib/simpledb.rb'
import 'lib/sqs.rb'
import 'lib/s3.rb'
require 'json'
require 'grocer'
require 'resque-status'

# Schedule a whole bunch of push notifications
class Process_APNS_PushNotifications
      include Resque::Plugins::Status
  @queue = :apns_notifier
  
  $certificate_path = nil
  $gateway = nil
  $pusher = nil
  $feedback = nil
  
  # Set the status of the notification 
  def self.set_notification_status(item,status,identifier = nil)
    item.attributes.replace(:status => status)
    if identifier
      item.attributes.replace(:scheduler_id => identifier)
    end
    item.attributes.replace(:updated => Time.now.iso8601)
  end
  
  # Set the status of the notification queue to process
  def self.set_queue_status(item,status,identifier = nil)
    item.attributes.replace(:status => status)
    if identifier
      item.attributes.replace(:process_id => identifier)
    end
    item.attributes.replace(:updated => Time.now.iso8601)
  end
  
  # Get the notification queue to process
   def self.get_pending_queue(domain,identifier = nil)
     # Look for new item in notification queue that are yet to be scheduled in Amazon Simple DB
     results = domain.items.where("status = 'pending' AND application_type = ?","ios")
     return results.first;
   end
   
  # Create Pusher
  def self.create_pusher
    if $pusher.nil?
      Resque.logger.info("Connecting to APNS..#{$certificate_path}, #{$gateway}")
      $pusher = Grocer.pusher(
         certificate: $certificate_path,      # required
         gateway: $gateway, 
         port: 2195,                     
         retries: 3                         
       )
    end
  end
   
  # Send the Push Message to all the given device tokens
  def self.send_push_message(bundle_id,device_tokens,notification_message)
    tokens = device_tokens.split(',')
    message = JSON.parse(notification_message)
    aps = message["aps"]
    badge = 0
    if aps.has_key?("badge")
      badge = Integer(aps.has_key?("badge"))
    end
    alert = aps["alert"]
    sound = aps["sound"]
    custom = message.clone
    custom.delete("aps")
    
    # Create pusher instance
    Process_APNS_PushNotifications.create_pusher
    
    tokens.each do |token|
      begin 
        notification = Grocer::Notification.new(
          device_token: token,
          alert: alert,
          badge: badge,
          sound: sound,
          custom: custom
          )
      
          $pusher.push(notification)
      rescue Exception => e
        Resque.logger.error("Token: #{token} failed with exception #{e.inspect}")
        Resque.logger.error(e.backtrace)
        $pusher = nil
        Process_APNS_PushNotifications.create_pusher
        next
      end
    end
  end
  
  # Call the feedback service to process error messages
  def self.process_feedback(domain)
    feedback_count = 0
    $feedback.each do |attempt|
      # If token doesn't exist skip it
     	unless domain.items[attempt.device_token].nil?
     	  Resque.logger.info("Device #{attempt.device_token} failed at #{attempt.timestamp}")
     	else 
     	  # Update it if necessary
     	  item = domain.items[attempt.device_token]
     	  if !device_token["active"]
     	    item.attributes.replace(:active => 0, :if => { :active => 1 })
     	    item.attributes.replace(:last_registration => attempt.timestamp)
     	    feedback_count = feeback_count + 1
     	  end
     	end
    end
    
    Resque.logger.info("APNS feedback tokens processed #{feedback_count}")
  end
  
  def name
    return "Process Apple Push Notifications"
  end
  
  # Execute the job
  def perform
    domain = SimpleDB.get_domain(SimpleDB.domain_for_notification_queues)
    
    tick()
  
    unless domain.nil?
      notification_queue_item = Process_APNS_PushNotifications.get_pending_queue(domain)
      
      tick()
      
      unless notification_queue_item.nil?
        process_identifier = SecureRandom.uuid
        
        # Set the scheduler_id in com.apple.notification
        Process_APNS_PushNotifications.set_queue_status(notification_queue_item,"processing",process_identifier)
        
        # This is necessary so that Amazon SimpleDB updates their db
        sleep(10)
        
        # Read the scheduler_id, if it is the same set status to scheduling 
        #  -- if not quit (this means some other worker has started working)
        if process_identifier.to_s != notification_queue_item.attributes['process_id'].values.first.to_s
          Resque.logger.info("process_id(#{process_identifier}) mismatch with 
                notification_queue_item.process_id(#{notification_queue_item.attributes['process_id'].values.first})")
          return
        end
        
        queue = SQS.get_queue(notification_queue_item.name)
        
        notification_domain = SimpleDB.get_domain(SimpleDB.domain_for_notification)
        notification_id = notification_queue_item.attributes['notification_id'].values.first
        notification_item = notification_domain.items[notification_id]
        
        bundle_id = notification_item.attributes['bundle_id'].values.first.to_s
        certificate = notification_item.attributes['certificate'].values.first.to_s
        $certificate_path = S3.mounted_certificate_path + certificate
        environment = notification_item.attributes['environment'].values.first.to_s
        notification_message = notification_item.attributes['message'].values.first.to_s
        $gateway = "gateway.sandbox.push.apple.com"
        if(environment.casecmp("production") == 0)
          $gateway = "gateway.push.apple.com"
        end
        
        feedback_gateway = "feedback.sandbox.push.apple.com"
        if(environment.casecmp("production") == 0)
          feedback_gateway = "feedback.push.apple.com"
        end
        feedback_domain_name = bundle_id.dup
        if(environment.casecmp("sandbox") == 0)
          feedback_domain_name << ".debug"
        end
        
        Resque.logger.info("Starting parallel push with process_id = #{process_identifier} and message #{notification_message}")
        
        begin   
          unless queue.nil?
            if queue.exists?
              count = 0
              Resque.logger.info("Sending Message : #{bundle_id}, #{environment}, #{notification_message}")
              
              queue.poll(:initial_timeout => true,:idle_timeout => 15) do |msg|
                Process_APNS_PushNotifications.send_push_message(bundle_id,msg.body,notification_message)
                count = count + 1
                at(count,queue.approximate_number_of_messages,"Processing #{notification_queue_item.name}")
              end
              queue.delete
            end

            # Delete the entry in the notification.queues table
            notification_queue_item.delete
          
            # Scan the notification.queues table to see if there are more entries in the table for the same notification_id
            pending_queues = domain.items.where("notification_id = ?",notification_id)
          
            # This is necessary for simple db to catch up
            sleep(5);

            # if there are, then quit, else then go ahead and mark this as complete
            if pending_queues.nil? || pending_queues.count == 0
                Process_APNS_PushNotifications.set_notification_status(notification_item,"feedback")
                
                $feedback = Grocer.feedback(
                  certificate: $certificate_path,          # required
                  gateway:     feedback_gateway,          # optional
                  port:        2196,                       # optional
                  retries:     3                          # optional
                )
                
                Resque.logger.info("Processing feedback for domain #{feedback_domain_name}")
                
                feedback_domain = SimpleDB.get_domain(feedback_domain_name)
                at(1,1,"Processing feedbacks")
                Process_APNS_PushNotifications.process_feedback(domain)
              
                Process_APNS_PushNotifications.set_notification_status(notification_item,"completed")
            end
          end
        rescue Exception => e
          Resque.logger.error(e.inspect)
          Resque.logger.error(e.backtrace)
          # Set the scheduler_id in com.apple.notification
          Process_APNS_PushNotifications.set_queue_status(notification_queue_item,"errored",process_identifier)
        end
        
        Resque.logger.info("Finished process with process_id = #{process_identifier}")
      end
    end
  end
  
end