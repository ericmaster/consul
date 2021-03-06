class Document < ActiveRecord::Base
  include DocumentsHelper
  include DocumentablesHelper
  has_attached_file :attachment, path: ":rails_root/public/system/:class/:prefix/:style/:filename"
  attr_accessor :cached_attachment

  belongs_to :user
  belongs_to :documentable, polymorphic: true

  # Disable paperclip security validation due to polymorphic configuration
  # Paperclip do not allow to user Procs on valiations definition
  do_not_validate_attachment_file_type :attachment
  validate :attachment_presence
  validate :validate_attachment_content_type,         if: -> { attachment.present? }
  validate :validate_attachment_size,                 if: -> { attachment.present? }
  validates :title, presence: true
  validates :user_id, presence: true
  validates :documentable_id, presence: true,         if: -> { persisted? }
  validates :documentable_type, presence: true,       if: -> { persisted? }

  after_save :remove_cached_document, if: -> { valid? && persisted? && cached_attachment.present? }

  def set_cached_attachment_from_attachment(prefix)
    self.cached_attachment = if Paperclip::Attachment.default_options[:storage] == :filesystem
                               attachment.path
                             else
                               prefix + attachment.url
                             end
  end

  def set_attachment_from_cached_attachment
    self.attachment = if Paperclip::Attachment.default_options[:storage] == :filesystem
                        File.open(cached_attachment)
                      else
                        URI.parse(cached_attachment)
                      end
  end

  Paperclip.interpolates :prefix do |attachment, style|
    attachment.instance.prefix(attachment, style)
  end

  def prefix(attachment, style)
    if !attachment.instance.persisted?
      "cached_attachments/user/#{attachment.instance.user_id}"
    else
      ":attachment/:id_partition"
    end
  end

  private

    def validate_attachment_size
      if documentable.present? &&
         attachment_file_size > documentable.class.max_file_size
        errors[:attachment] = I18n.t("documents.errors.messages.in_between",
                                      min: "0 Bytes",
                                      max: "#{max_file_size(documentable)} MB")
      end
    end

    def validate_attachment_content_type
      if documentable.present? &&
         !accepted_content_types(documentable).include?(attachment_content_type)
        errors[:attachment] = I18n.t("documents.errors.messages.wrong_content_type",
                                      content_type: attachment_content_type,
                                      accepted_content_types: humanized_accepted_content_types(documentable))
      end
    end

    def attachment_presence
      if attachment.blank? && cached_attachment.blank?
        errors[:attachment] = I18n.t("errors.messages.blank")
      end
    end

    def remove_cached_document
      File.delete(cached_attachment) if File.exists?(cached_attachment)
    end

end
