$VERBOSE = nil

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk-s3'
require 'metaractor'

class FindCache
  include Metaractor

  required :keys
  required :bucket
  required :prefix

  def call
    resolved_key = nil
    resolved_time = nil

    context.keys.each do |key|
      response = s3_client.list_objects_v2(
        bucket: context.bucket,
        prefix: full_prefix(key: key)
      )

      raise "Truncated Response!" if response.is_truncated

      response.contents.each do |object|
        if resolved_key.nil?
          resolved_key = object.key
          resolved_time = object.last_modified
        elsif object.key.length > resolved_key.length
          resolved_key = object.key
          resolved_time = object.last_modified
        elsif object.key.length == resolved_key.length && object.last_modified > resolved_time
          resolved_key = object.key
          resolved_time = object.last_modified
        end
      end
    end

    if resolved_key.nil?
      context.resolved_key = nil
    else
      # Find last path segment and remove file extension
      context.resolved_key = resolved_key.split('/').last.split('.').first
    end
  end

  private
  def s3_client
    return @_s3 if defined?(@_s3)

    @_s3 = Aws::S3::Client.new(region: 'us-east-1')
  end

  def full_prefix(key:)
    "#{context.prefix}/#{key}"
  end
end

