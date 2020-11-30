require 'find_cache'

if ARGV.length < 3
  puts 'USAGE'
  puts 'ruby -I . cli.rb BUCKET PREFIX [KEYS]'
  exit 2
end

begin
  bucket = ARGV[0]
  prefix = ARGV[1]
  keys = ARGV[2..-1]

  result = FindCache.call!(
    bucket: bucket,
    prefix: prefix,
    keys: keys
  )

  if result.resolved_key.nil?
    exit 1
  else
    puts result.resolved_key
  end
rescue => e
  puts e.full_message
  exit 2
end
