require 'open-uri'
require 'json'

MIN = Gem::Version.new('3.2')

INDEX = URI('https://raw.githubusercontent.com/ruby/setup-ruby/refs/heads/master/ruby-builder-versions.json')

index = JSON.parse(INDEX.open(&:read))
crubies = index['ruby'].filter do |v|
  next if v =~ /asan/
  next if v == '3.5.0-preview1'  # will be released as 4.0
  Gem::Version.new(v) >= MIN rescue nil
end.group_by {|v| v[/\A\d+\.\d+/] }.values.map(&:last)

ubuntu_compilers = [
  { cc: 'clang', cxx: 'clang++' },
  { cc: 'gcc', cxx: 'g++' },
]
macos_compilers = [
  { cc: 'clang', cxx: 'clang++' },
  { cc: 'gcc-15', cxx: 'g++-15' },
]

runners = %w[ubuntu-24.04 ubuntu-24.04-arm].product(ubuntu_compilers) + %w[macos-15-intel macos-15].product(macos_compilers)


matrix = runners.flat_map {|runner, compilers|
  [{ runner: runner, compilers: compilers }].product(crubies).map {|h, ruby| h.merge(ruby: ruby) }
}

matrix = matrix.map {|h|
  runner = h.fetch(:runner)
  ruby = h.fetch(:ruby)
  cc = h[:compilers].fetch(:cc)
  h.merge(
    artifact_tag: "ghcr.io/hanazuki/ruby-builder:ruby-#{ruby}_#{runner}_#{cc}",
  )
}

puts JSON.dump(matrix)
