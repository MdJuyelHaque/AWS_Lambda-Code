# frozen_string_literal: t:wqrue
require 'logger'
require 'json'
require 'uri'
require 'net/http'
require 'openssl'

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)
 
 logger.info(event.to_json)
  logger.info(context.to_json)
  logger.info(event['responsePayload']['body'])
  alerts = JSON.parse(event['responsePayload']['body'])
  alerts.each do |e|
    SlackAlert.alert(e['dir'], e['env'], e['dif'], e['processed'], e["channel"])
  end
end

# sends slack alrts
class SlackAlert
  def self.alert(_dir, _env, _new_files, _processed_files, _channel)
    logger = Logger.new($stdout)
    # 'Sending Slack alert'
    url = URI('https://hooks_url')

    http = Net::HTTP.new(url.host, url.port)
    #http.set_debug_output $stderr
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/json'
    request.body = body(_dir, _env, _new_files, _processed_files, _channel)
    logger.info(request.body)

    http.request(request)
  end

  def self.body(_dir, _env, _new_files, _processed_files, _channel)
    jhash = {
      'channel' => _channel,
      'username' => "Filesystem Monitor #{_env}",
      'icon_emoji' => ':interrobang:',
      'blocks' => [
        {
          "type" => "section",
          "text" => {
            "type" => "mrkdwn",
            "text" => "<!here|Team> In the *#{_env}* environment"
          }
        }
      ],
      'attachments' => []
    }
    
    if _new_files.length > 0
      jhash['attachments'].append({
            "fallback" => "New files in #{_dir} were not processed: #{_new_files}",
            "title" => "New files in `#{_dir}` were not processed",
            "text" => "#{_new_files}",
            "color" => "#fa0202"
      })
    end
    
    if _processed_files.length > 0
      jhash['attachments'].append({
            "fallback" => "Completed files in #{_dir} have now been processed: #{_new_files}",
            "title" => "Completed files processing in `#{_dir}`, files have now been processed",
            "text" => "#{_processed_files}",
            "color" => "#00fa19"
      })
    end

    jhash.to_json
  end
end
