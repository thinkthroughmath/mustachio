module Mustachio
  class Rekognition
    class Error < StandardError; end

    class << self
      REKOGNITION_KEY = ENV['MUSTACHIO_REKOGNITION_KEY'] || raise('please set MUSTACHIO_REKOGNITION_KEY')
      REKOGNITION_SECRET = ENV['MUSTACHIO_REKOGNITION_SECRET'] || raise('please set MUSTACHIO_REKOGNITION_SECRET')


      def get_response(file)
        client = Face.get_client(api_key: REKOGNITION_KEY, api_secret: REKOGNITION_SECRET)
        client.faces_detect(file: Faraday::UploadIO.new(file, content_type(file)))
      end

      def content_type file
        `file -b --mime #{file.path}`.strip.split(/[:;]\s+/)[0]
      end

      def validate_response(json)
        unless json['status'] == 'success'
          msg = json['status']
          raise Error.new("SkyBiometry API: #{msg}")
        end
      end

      def face_detection file
        json = self.get_response file
        self.validate_response(json)

        json['photos'].first['tags'].map do |entry|
          width = entry['width']
          height = entry['height']

          mouth_center, nose = entry.values_at('mouth_center', 'nose').map do |dims|
            {
              'x' => ((dims['x'].to_f / width.to_f) * 100.0),
              'y' => ((dims['y'].to_f / height.to_f) * 100.0)
            }
          end

          { 'mouth_center' => mouth_center, 'nose' => nose }
        end
      end
    end
  end
end
