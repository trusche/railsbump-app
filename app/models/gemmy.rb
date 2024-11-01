class Gemmy < ApplicationRecord
  FORBIDDEN_NAMES = %w(
    new
    edit
    rails
  )

  validates :name, presence: true, uniqueness: { allow_blank: true }, exclusion: FORBIDDEN_NAMES

  delegate :to_param, :to_s, to: :name

  # Check all pending compats for compatibility
  def check_compatibility
    compats.pending.each do |compat|
      Compats::Check.new.call(compat)
    end
  end

  # Check all compats for compatibility
  def check_compatibility!
    compats.each do |compat|
      Compats::Check.new.check!(compat)
    end
  end

  def compats
    Compat.where(id: compat_ids)
  end

  def dependencies
    dependencies_and_versions
      .keys
      .map { JSON.parse _1 }
  end

  def last_checked_at
    compats.maximum(:checked_at)
  end

  def versions(dependencies = nil)
    version_groups =
      dependencies ?
      dependencies_and_versions.fetch_values(*dependencies.map { JSON.generate _1 }) :
      dependencies_and_versions.values

    version_groups
      .flatten
      .map(&Gem::Version.method(:new))
      .sort
  end
end

# == Schema Information
#
# Table name: gemmies
#
#  id                        :integer          not null, primary key
#  compat_ids                :json             not null
#  dependencies_and_versions :json
#  name                      :text
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
