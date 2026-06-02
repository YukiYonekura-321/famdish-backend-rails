require "aws-sdk-s3"
require "open-uri"

class UploadGeneratedImageService
  def self.call(record, fal_image_url, suffix: nil, update_db: true)
    new(record, fal_image_url, suffix: suffix, update_db: update_db).call
  end

  def initialize(record, fal_image_url, suffix: nil, update_db: true)
    @record = record
    @fal_image_url = fal_image_url
    @suffix = suffix
    @update_db = update_db
  end

  def call
    return if @fal_image_url.blank? || @record.blank?
    # すでに自前のS3にアップロード済みのURLであればスキップ
    return @fal_image_url if @fal_image_url.include?("#{s3_bucket}.s3")

    # Railsのクラス名からフォルダ名を自動判定（例: Suggestion -> suggestions, Recipe -> recipes）
    folder_name = @record.class.to_s.underscore.pluralize
    key = "#{folder_name}/#{@record.id}#{@suffix}.png"

    begin
      # 指定された一時URLから画像データをオープン
      image_data = URI.open(@fal_image_url)

      # S3へアップロード
      s3_client.put_object(
        bucket: s3_bucket,
        key: key,
        body: image_data,
        content_type: "image/png"
      )

      # S3上の永久保存URLを構築
      s3_url = "https://#{s3_bucket}.s3.#{aws_region}.amazonaws.com/#{key}"

      # 対象レコードの image_url カラムを更新
      if @update_db
        @record.update!(image_url: s3_url)
      end
      s3_url
    rescue => e
      Rails.logger.error "[UploadGeneratedImageService] Failed to upload image for #{@record.class} ID: #{@record.id}. Error: #{e.message}"
      nil
    end
  end

  private

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      region: aws_region,
      access_key_id: ENV["AWS_ACCESS_KEY_ID"],
      secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )
  end

  def aws_region
    ENV["AWS_REGION"] || "ap-northeast-1"
  end

  def s3_bucket
    ENV["S3_BUCKET"]
  end
end
