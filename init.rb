$:.unshift File.expand_path("../vendor/progress/lib", __FILE__)

require "cgi"
require "net/http"
require "net/https"
require "progress"
require "tmpdir"
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

  # apps:import FILENAME
  #
  # import an app
  #
  def import
    filename = shift_argument || error("must specify FILENAME")
    validate_arguments!

    upload_bundle app, filename
    puts "Imported to #{app}"
  end

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

  # apps:clone NEWNAME
  #
  # clone an app to NEWNAME
  #
  # -r, --region REGION  # specify region for this app to run on
  #
  def clone
    name_new = shift_argument || error("must specify NEWNAME")
    name_old = app

    action("Creating #{name_new}") do
      app = api.post_app({ :name => name_new, :stack => "cedar", :region => options[:region] })
    end

    Dir.mktmpdir do |dir|
      download_bundle name_old, "#{dir}/bundle.tgz"
      upload_bundle name_new, "#{dir}/bundle.tgz"
    end

    puts "Cloned #{name_old} to #{name_new}"
  end

private

  def bundle(app)
    RestClient::Resource.new bundle_host, "", Heroku::Auth.api_key
  end

  def upload_bundle(app, filename)
    action("Uploading bundle") do
      res = bundle(app)["/apps/#{app}/bundle"].post(
        :bundle => File.open(filename, "rb"),
        :description => "Imported from #{File.basename(filename)}",
        :user => Heroku::Auth.user
      )
      status json_decode(res.body)["release"]
    end
  rescue RestClient::Forbidden => ex
    error ex.http_body
  end

  def download_bundle(app, filename)
    file = File.open(filename, "wb")
    uri  = URI.parse("#{bundle_host}/apps/#{app}/bundle")
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

  def bundle_host
    ENV["BUNDLE_HOST"] || "https://bundle-builder.herokuapp.com"
  end

end
