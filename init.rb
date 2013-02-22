$:.unshift File.expand_path("../vendor/progress/lib", __FILE__)

require "cgi"
require "net/http"
require "net/https"
require "progress"
require "zlib"

class Heroku::API
  def get_release_slug(app)
    request(
      :expects  => 200,
      :method   => :get,
      :path     => "/apps/#{app}/release_slug"
    )
  end
end

class Heroku::Command::Apps < Heroku::Command::Base

  # apps:export FILENAME
  #
  # export an app
  #
  def export
    filename = shift_argument || "#{app}.tgz"
    validate_arguments!

    download_bundle app, filename
    puts "Exported to " + File.expand_path(filename)
  end

private

  def download_bundle(app, filename)
    file = File.open(filename, "wb")
    uri  = URI.parse(slug_converter_url(app))
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = Net::HTTP::Get.new uri.request_uri

    req.basic_auth "", Heroku::Auth.api_key

    print "Creating bundle for #{app}... "

    http.request(req) do |res|
      error res.body unless res.code.to_i == 200
      length = res.fetch("content-length").to_i
      puts "done"

      Progress.start("Downloading", res.fetch("Content-Length").to_i) do
        begin
          res.read_body do |chunk|
            file.print chunk
            Progress.step chunk.length
          end
        rescue Exception => ex
          error "download failed: #{ex.message}"
        end
      end
    end
  ensure
    file.close
  end

  def slug_converter_url(app)
    host = ENV["SLUG_CONVERTER_HOST"] || "https://bundle-builder.herokuapp.com"
    "#{host}/apps/#{app}/bundle.tgz"
  end

end
