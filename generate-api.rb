#!/usr/bin/env ruby

JAR_CACHE_DIR = ".jarCache"
OPEN_API_SCHEMA = "anyOf.yaml"
TARGET_DIR = "generated_lib"
LIB_NAME= "generated_lib"

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

openapi = Jar.new("org.openapitools", "openapi-generator-cli", "5.1.0")

openapi.ensure

openapi_cli = "java -jar #{openapi.localPath}"

# cleanup
`rm -rf #{TARGET_DIR}`

# generate
puts `#{openapi_cli} generate --enable-post-process-file -i #{OPEN_API_SCHEMA} -g dart-dio-next --output "#{TARGET_DIR}" --additional-properties "pubName=#{LIB_NAME}"`

# force update & pretty formatting
puts `cd #{TARGET_DIR} && flutter pub get`
puts `dartfmt -w #{TARGET_DIR}`
