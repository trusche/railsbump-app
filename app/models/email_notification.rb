class EmailNotification
  include ActiveModel::Model

  NAMESPACE       = "email_notifications"
  NAMESPACE_REGEX = /\A#{Regexp.escape NAMESPACE}:(.+)/

  attr_accessor :email, :notifiable

  validates :email,
    presence: true,
    format: {
      with:        URI::MailTo::EMAIL_REGEXP,
      allow_blank: true
    }
  validates :notifiable, presence: true

  def self.all
    Kredis.redis.keys("#{NAMESPACE}:*").flat_map do |key|
      unless notifiable = GlobalID::Locator.locate(key[NAMESPACE_REGEX, 1])
        raise "Could not find notifiable: #{key}"
      end

      Kredis.redis.smembers(key).map do |email|
        new notifiable: notifiable, email: email
      end
    end
  end

  def notifiable_gid=(value)
    self.notifiable = GlobalID::Locator.locate(value)
  end

  def save
    return false unless valid?

    Kredis.redis.sadd key, email
    true
  end

  def delete
    Kredis.redis.srem key, email
  end

  private

    def key
      [NAMESPACE, notifiable.to_global_id].join(":")
    end
end
