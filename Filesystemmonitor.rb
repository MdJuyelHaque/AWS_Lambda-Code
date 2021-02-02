# frozen_string_literal: true
require 'logger'
require 'json'

def lambda_handler(event:, context:)
  logger = Logger.new($stdout)
 # logger.info(event.to_json)
  #logger.info(context.to_json)

  mnt = '/mnt/dir/'
  dirs = Array[
    'website/incoming',
    'institutional/incoming'
  ]

  old_file = mnt + 'file_monitor.json'

  new_count = {}
  alerts = []

  dirs.each do |d|
    dir = mnt + d
    logger.info("counting files in #{dir}")
    new_count[d] = Dir[File.join(dir, '**', '*')].select{ |file| File.file?(file) }.map{ |f| File.basename(f) }
  end

  new_json = new_count.to_json

  if File.exist?(old_file)
    file = File.open(old_file)
    old_json = file.read
    #logger.info(old_json)
    old_hash = JSON.parse(old_json)
    new_count.each do |k, c|
      new_files_dif = c - old_hash[k]
      processed_files_dif = old_hash[k] - c
      logger.info({ :old_hash => old_hash[k], :dif => new_files_dif }.to_json)
      if new_files_dif.length + processed_files_dif.length > 0
        alerts << { :dir => k, :env => ENV['ENV'], :dif=> new_files_dif.join(", "), :processed => processed_files_dif.join(", "), :channel => ENV['SLACKCHANNEL'] }
      else
        logger.info(k + ' is all good')
      end
    end
  else
    logger.info('## Creating new file')
    File.new(old_file, 'w+')
  end
  logger.info(alerts)

  # write new file
  File.write(old_file, new_json)
  { statusCode: 200, body: JSON.generate(alerts) }

end
