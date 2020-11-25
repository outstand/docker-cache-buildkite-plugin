require 'find_cache'

if ARGV.length < 3
  puts 'USAGE'
  puts 'ruby -I . cli.rb BUCKET PREFIX [KEYS]'
  exit 1
end

bucket = ARGV[0]
prefix = ARGV[1]
keys = ARGV[2..-1]

result = FindCache.call!(
  bucket: bucket,
  prefix: prefix,
  keys: keys
)

puts result.resolved_key
