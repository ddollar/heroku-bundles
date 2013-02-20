$:.unshift File.expand_path("../vendor/minitar/lib", __FILE__)
$:.unshift File.expand_path("../vendor/progress/lib", __FILE__)

require "zlib"
require "archive/tar/minitar"
require "progress"

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

  EXPORT_COMMAND = <<-COMMAND
    fakeroot tar czf /tmp/app.tgz . && \
    cat /tmp/app.tgz
  COMMAND

  # apps:export FILENAME
  #
  # export an app
  #
  def export
    filename = shift_argument || "#{app}.tgz"
    validate_arguments!

    release = api.get_release_slug(app).body
    slug    = release["slug_url"]
    config  = api.get_config_vars(app).body

    puts "Exporting #{app}..."

    download_file slug, "bundle.tgz"
    inject_env config, "bundle.tgz"
    puts "Exported to " + File.expand_path(filename)
  end

private

  def download_file(url, filename)
    file = File.open(filename, "wb")
    uri  = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    req = Net::HTTP::Get.new uri.request_uri

    http.request(req) do |res|
      length = res.fetch("content-length").to_i
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

  def inject_env(config, filename)
    gz  = Zlib::GzipWriter.new(File.open(filename, "wb"))
    tgz = Archive::Tar::Minitar::Writer.new(gz)
    data = config.inject("") do |ax, (key, value)|
      ax + "#{key}=#{value}\n"
    end
    tgz.add_file_simple(".env", :mode => 0600, :size => data.length, :uid => 0, :gid => 0) do |io|
      io.write data
    end
  ensure
    tgz.close
    gz.close
  end

end
