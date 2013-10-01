module RunRTF
  module Rails
    class Converter

      NO_UNRTF = "You must have unrtf installed to use RunRTF."
      PIC_WIDTH = 320

      class << self

        # @param [String] rtf The path to the rtf to be converted
        # @param [Boolean] inline Flag to return the inline html or a full page with <html> and <header> tags
        # @param [String] img_format The desired format for embedded images
        # @return [String] Html markup for the rtf
        def convert(rtf="", inline=true, img_format="jpg")
          puts NO_UNRTF && return if !unrtf_present?
          @rtf = rtf
          @rtf_base_name = File.basename(@rtf).split(".").first
          @inline = inline
          @img_format = img_format
          @img_dir = "#{Dir.pwd}/app/assets/images/rtf_images"
          generate_html
        end

        protected

        def unrtf_present?
          system("unrtf --version")
        end

        def generate_html
          # Convert rtf to html
          cmd  = 'unrtf --html'
          cmd += ' --inline' if @inline
          cmd += " #{@rtf}"
          html = `#{cmd}`

          # Parse the html
          @parsed = Nokogiri::HTML.parse(html)

          # Change border size to zero
          @parsed.xpath("//table/@border").each { |b| b.value = "0" }

          # Expand tables
          @parsed.xpath("//table").each { |b| b['width'] = "100%" }

          # Align left
          @parsed.xpath("//@align").map{ |e| e.value = "left" }

          # Convert images
          convert_images if @parsed.xpath("//img").count > 0

          # Return html as inline or full
          @inline ? @parsed.xpath("//body").to_html.gsub("<body>", "").gsub("</body>", "") : @parsed.to_html

        end

        def convert_images
          begin
            @parsed.xpath("//img").map do |img|
              orig_img = img['src']
              img_root_name = orig_img.split(".").first
              i = QuickMagick::Image.read(orig_img).first
              new_img_name = "#{@img_dir}/#{@rtf_base_name}/#{img_root_name}.#{@img_format}"

              # Change src name in html
              img['src'] = "/assets/rtf_images/#{@rtf_base_name}/#{img_root_name}.#{@img_format}"

              # Resize to PIC_WIDTH and proportional height
              ratio = i.width / i.height.to_f
              new_height = PIC_WIDTH / ratio
              i.resize "#{PIC_WIDTH}X#{new_height}!"

              # Make image directory
              Dir.mkdir(@img_dir) unless Dir.exists?(@img_dir)
              Dir.mkdir("#{@img_dir}/#{@rtf_base_name}") unless Dir.exists?("#{@img_dir}/#{@rtf_base_name}")

              # Convert the image
              i.convert(new_img_name)

              # Remove the original
              File.delete(orig_img)

            end
          rescue => e
            $stdout.puts "Something went wrong while converting the embedded images:\n#{e}"
          end
        end

      end
    end
  end
end

require 'nokogiri'
require 'quick_magick'
