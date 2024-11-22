require 'open-uri'
require 'json'

INDEX = URI('https://raw.githubusercontent.com/ruby/setup-ruby/refs/heads/master/ruby-builder-versions.json')

index = JSON.parse(INDEX.open(&:read))
crubies = index['ruby'].grep(/\A3\./).group_by {|v| v[/\A\d+\.\d+/] }.values.map(&:last)

ubuntu_compilers = [
  { cc: 'clang', cxx: 'clang++' },
  { cc: 'gcc', cxx: 'g++' },
]
macos_compilers = [
  { cc: 'clang', cxx: 'clang++' },
  { cc: 'gcc-14', cxx: 'g++-14' },
]

runners = %w[ubuntu-24.04].product(ubuntu_compilers) # + %w[macos-14].product(macos_compilers)


matrix = runners.flat_map {|runner, compilers|
  [{ runner: runner, compilers: compilers }].product(crubies).map {|h, ruby| h.merge(ruby: ruby) }
}

matrix = matrix.map {|h| h.merge(artifact_key: "ruby-#{h[:ruby]}_#{h[:runner]}_#{h[:compilers][:cc]}") }

puts JSON.dump(matrix)
