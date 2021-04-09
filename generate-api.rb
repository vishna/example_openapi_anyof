#!/usr/bin/env ruby

JAR_CACHE_DIR = ".jarCache"
OPEN_API_SCHEMA = "anyOf.yaml"
TARGET_DIR = "generated_lib"
LIB_NAME= "generated_lib"
JAR_VERSION = "5.2"

`mkdir -p #{JAR_CACHE_DIR}`

class Jar
  attr_reader :group, :artifactId, :version

  def initialize(group, artifactId, version)
    @group = group
    @artifactId = artifactId
    @version = version
  end

  def filename
  	"#{artifactId}-#{version}.jar"
  end

  def downloadUrl
  	"https://repo1.maven.org/maven2/#{group.gsub('.', '/')}/#{artifactId}/#{version}/#{filename}"
  end

  def ensure
  	target = localPath
  	if !File.file?(target) then
  		puts "Downloading #{filename}"
  		`wget -U "Any User Agent" -O #{target} #{downloadUrl}`
  	end
  end

  def localPath
  	"#{JAR_CACHE_DIR}/#{filename}"
  end
end

def repoBuild
  `rm -rf dart-openapi-maven`
  `git clone git@github.com:vishna/dart-openapi-maven.git`
  `cd dart-openapi-maven && git checkout anyof_support && mvn package`
  `cp dart-openapi-maven/target/openapi-dart-generator-#{JAR_VERSION}-SNAPSHOT.jar #{JAR_CACHE_DIR}/dev.jar`
  `rm -rf dart-openapi-maven`
end

def localBuild
  puts `cd /Users/vishna/Projects/dart-openapi-maven && mvn package`
  `cp /Users/vishna/Projects/dart-openapi-maven/target/openapi-dart-generator-#{JAR_VERSION}-SNAPSHOT.jar #{JAR_CACHE_DIR}/dev.jar`
end

dartgen = Jar.new("com.bluetrainsoftware.maven", "openapi-dart-generator", "4.2")
openapi = Jar.new("org.openapitools", "openapi-generator-cli", "5.1.0")

dartgen.ensure
openapi.ensure

openapi_cli = "java -cp #{openapi.localPath}:#{dartgen.localPath} org.openapitools.codegen.OpenAPIGenerator"

# pass dev parameter to checkout repo and build jar locally
if ARGV[0] == "dev" then
  repoBuild()
  openapi_cli = "java -cp #{openapi.localPath}:#{JAR_CACHE_DIR}/dev.jar org.openapitools.codegen.OpenAPIGenerator"
end

# pass local parameter to build with locally edited code
if ARGV[0] == "local" then
  localBuild()
  openapi_cli = "java -cp #{openapi.localPath}:#{JAR_CACHE_DIR}/dev.jar org.openapitools.codegen.OpenAPIGenerator"
end

# cleanup
`rm -rf #{TARGET_DIR}`

# generate
puts `#{openapi_cli} generate --enable-post-process-file -i #{OPEN_API_SCHEMA} -g dart2-api --output "#{TARGET_DIR}" --additional-properties "pubName=#{LIB_NAME}"`

# force update & pretty formatting
puts `cd #{TARGET_DIR} && flutter pub get`
puts `dartfmt -w #{TARGET_DIR}`

puts `flutter analyze`
