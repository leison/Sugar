
require 'pp'

@version  = ARGV[0]
@custom_packages = ARGV[1..-1]

if !@version
  puts "No version specified!"
  exit
end

@packages = ['core','es5','array','date','date_ranges','function','number','object','regexp','string','inflections','language']
@default_packages = @packages.values_at(0,1,2,3,4,5,6,7,8,9)
@delimiter = 'console.info("-----BREAK-----");'
@full_path = "release/#{@version}"
@copyright = File.open('release/copyright.txt').read.gsub(/VERSION/, @version)

@precompiled_notice = <<NOTICE
Note that the files in this directory are not prodution ready. They are
intended to be concatenated together and wrapped with a closure.
NOTICE

`mkdir release/#{@version}`
`mkdir release/#{@version}/precompiled`
`mkdir release/#{@version}/precompiled/minified`
`mkdir release/#{@version}/precompiled/development`


def concat
  File.open('tmp/uncompiled.js', 'w') do |file|
    @packages.each do |p|
      file.puts content = File.open("lib/#{p}.js").read + @delimiter
    end
  end
end

def create_development
  content = ''
  @packages.each do |p|
    content << File.open("lib/#{p}.js").read
    `cp lib/#{p}.js release/#{@version}/precompiled/development/#{p}.js`
  end
  File.open("release/#{@version}/sugar-#{@version}-full.development.js", 'w').write(@copyright + wrap(content))
end

def compile
  command = "java -jar script/jsmin/compiler.jar --warning_level QUIET --compilation_level ADVANCED_OPTIMIZATIONS --externs script/jsmin/externs.js --js tmp/uncompiled.js --js_output_file tmp/compiled.js"
  puts "EXECUTING: #{command}"
  `#{command}`
end

def split_compiled
  contents = File.open('tmp/compiled.js', 'r').read.split(@delimiter)
  @packages.each_with_index do |name, index|
    File.open("#{@full_path}/precompiled/minified/#{name}.js", 'w') do |f|
      f.puts contents[index].gsub(/\A\n+/, '')
    end
  end
  `echo "#{@precompiled_notice}" > release/#{@version}/precompiled/readme.txt`
end

def create_packages
  create_package('full', @packages)
  create_package('default', @default_packages)
  if @custom_packages.length > 0
    create_package('custom', @custom_packages)
  end
end

def create_package(name, arr)
  contents = ''
  arr.each do |s|
    contents << File.open("#{@full_path}/precompiled/minified/#{s}.js").read
  end
  contents = @copyright + wrap(contents.sub(/\n+\Z/m, ''))
  File.open("#{@full_path}/sugar-#{@version}-#{name}.min.js", 'w').write(contents)
end

def wrap(js)
  "(function(){#{js}})();"
end

def cleanup
  `rm tmp/compiled.js`
  `rm tmp/uncompiled.js`
  `cd release;rm sugar-edge.js;ln -s #{@version}/sugar-#{@version}-full.development.js sugar-edge.js`
end

concat
compile
split_compiled
create_packages
create_development
cleanup

