class StatisticsController < ApplicationController
  skip_authorize_resource
  skip_authorization_check
  before_action { authorize! :view, :statistics }

  def index
    @stats = Rails.cache.fetch("queries-#{cache_key_for_status}") do
      {
        periods: [
          {title: 'Inskrivna denna månad', data: stats_for_collection(registered_this_month)},
          {title: 'Inskrivna detta kvartal', data: stats_for_collection(registered_this_quarter)},
          {title: 'Inskrivna detta år', data: stats_for_collection(registered_this_year)},
        ],
        homes: Home.count,
        seats: Home.sum(:seats),
        guaranteed_seats: Home.sum(:guaranteed_seats),
        movable_seats: Home.sum(:movable_seats),
        total_placement_time: Placement.all.map(&:placement_time).inject(&:+)
      }
    end
  end

  private

  def stats_for_collection(collection)
    {
      refugees: collection.count,
      per_gender: Gender.all.map { |g| "#{collection.where(gender: g).count} är #{g.name.downcase}" }.join(', '),
      in_transit: collection.where(
          residence_permit_at: nil,
          temporary_permit_starts_at: nil,
          municipality: nil,
          municipality_placement_migrationsverket_at: nil,
          municipality_placement_per_agreement_at: nil,
          deregistered: nil).count,
      with_residence_permit: collection.where.not(residence_permit_at: nil).count,
      with_residence_permit: collection.where.not(residence_permit_at: nil).count,
      with_temporary_permit: collection.where.not(temporary_permit_starts_at: nil).count,
      with_placement: collection.includes(:placements).where.not(placements: { refugee_id: nil }).count,
      with_municipality_placement: collection.where.not(municipality: nil).count,
      with_municipality_placement_in_malmo: collection.joins(:municipality).where("municipalities.name like ?", "malmö%").count,
      deregistered: collection.where.not(deregistered: nil).count,
      top_countries: collection.joins(:countries).select('countries.name').group('countries.name').count('countries.name').sort_by{ |key, value| value }.reverse,
      top_languages: collection.joins(:languages).select('languages.name').group('languages.name').count('languages.name').sort_by{ |key, value| value }.reverse,
    }
  end

  private

  def registered_this_year
    @registered_this_year ||=
      Refugee.where('registered >= ?', Date.today.beginning_of_year)
  end

  def registered_this_quarter
    @registered_this_quarter ||=
      Refugee.where('registered >= ?', Date.today.beginning_of_quarter)
  end

  def registered_this_month
    @registered_this_month ||=
      Refugee.where('registered >= ?', Date.today.beginning_of_month)
  end

  def cache_key_for_status
    @cache_key_for_status ||=
      count = Refugee.count + Home.count + Placement.count
      latest_update = [
        Refugee.maximum(:updated_at),
        Home.maximum(:updated_at),
        Placement.maximum(:updated_at)].sort.last.try(:utc).try(:to_s, :number)
      "status/index-#{Date.today.to_s}-#{count}-#{latest_update}"
  end
end
