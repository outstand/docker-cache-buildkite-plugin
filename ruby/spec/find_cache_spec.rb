require 'find_cache'

RSpec.describe FindCache do
  let(:bucket) { 'outstand-buildkite-data' }
  let(:prefix) { 'outstand/docker-cache-buildkite-plugin/fixtures' }

  it 'fetches the most specific cache key' do
    keys = [
      'v1-bundler-cache-linux-x86_64-da39a3ee5e6b4b0d3255bfef95601890afd80709-2cd5c1d0571d78795437ff7ebd0d3bf264d7846b'
    ]

    result = FindCache.call(
      keys: keys,
      bucket: bucket,
      prefix: prefix
    )

    expect(result).to be_success
    expect(result.resolved_key).to eq 'v1-bundler-cache-linux-x86_64-da39a3ee5e6b4b0d3255bfef95601890afd80709-2cd5c1d0571d78795437ff7ebd0d3bf264d7846b'
  end

  it 'fetches the newest key matching a prefix' do
    keys = [
      'v1-bundler-cache-linux-x86_64-'
    ]

    result = FindCache.call(
      keys: keys,
      bucket: bucket,
      prefix: prefix
    )

    expect(result).to be_success
    expect(result.resolved_key).to eq 'v1-bundler-cache-linux-x86_64-da39a3ee5e6b4b0d3255bfef95601890afd80709-9cf9e79ffe0d01c9e3d6a143ac63a9c9ecc8015b'
  end

  it 'returns nil when no key is found' do
    keys = [
      'do-not-find-me'
    ]

    result = FindCache.call(
      keys: keys,
      bucket: bucket,
      prefix: prefix
    )

    expect(result).to be_success
    expect(result.resolved_key).to be_nil
  end

  it 'respects key order' do
    keys = [
      'v1-bundler-cache-linux-x86_64-branch-name-',
      'v1-bundler-cache-linux-x86_64-'
    ]

    result = FindCache.call(
      keys: keys,
      bucket: bucket,
      prefix: prefix
    )

    expect(result).to be_success
    expect(result.resolved_key).to eq 'v1-bundler-cache-linux-x86_64-branch-name-deadbeef'
  end

  it 'preserves dots in the key name' do
    keys = [
      'v1-bundler-cache-linux-x86_64-longer-branch-name-1.2.3'
    ]

    result = FindCache.call(
      keys: keys,
      bucket: bucket,
      prefix: prefix
    )

    expect(result).to be_success
    expect(result.resolved_key).to eq 'v1-bundler-cache-linux-x86_64-longer-branch-name-1.2.3'

  end
end
