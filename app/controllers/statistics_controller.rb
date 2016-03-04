class StatisticsController < ApplicationController
  skip_authorize_resource
  skip_authorization_check
  before_action { authorize! :view, :statistics }

  def index
    @stats = Rails.cache.fetch("queries-#{cache_key_for_status}") do
      {
        periods: [
          { id: 'all',
            title: 'Aktuella ärenden just nu',
            data: stats_for_collection(all_registered),
            chart: {
              title: 'Antal nyanlända barn per dag förra veckan',
              data: [
                ['X', 'antal barn'],
                ['mån', registered_per_date(last_week_start)],
                ['tis', registered_per_date(last_week_start + 1.day)],
                ['ons', registered_per_date(last_week_start + 2.day)],
                ['tor', registered_per_date(last_week_start + 3.day)],
                ['fre', registered_per_date(last_week_start + 4.day)],
                ['lör', registered_per_date(last_week_start + 5.day)],
                ['sön', registered_per_date(last_week_start + 6.day)]
              ]
            }
          },
          { id: 'this-month',
            title: 'Nyinskrivna aktuell månad',
            data: stats_for_collection(registered_this_month)
          },
          { id: 'this-year',
            title: 'Nyinskrivna detta år',
            data: stats_for_collection(registered_this_year) }
        ],

        homes: Home.count,
        home_by_owner_type: OwnerType.all.map { |ot|
          "#{Home.where(owner_type: ot).count} är #{ot.name}" }.join(', '),

        current_placements: Placement.current_placements,
        current_placements_per_owner_type: OwnerType.all.map { |ot|
          "#{Placement.current_placements.includes(:home).where(
            homes: { owner_type_id: ot.id }).count} på #{ot.name}" }.join(', '),

        guaranteed_seats: Home.sum(:guaranteed_seats),
        movable_seats: Home.sum(:movable_seats),
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
      with_temporary_permit: collection.where.not(temporary_permit_starts_at: nil).count,
      with_placement: collection.includes(:placements).where.not(placements: { refugee_id: nil }).count,
      with_municipality_placement: collection.where.not(municipality: nil).count,
      with_municipality_placement_in_malmo: collection.joins(:municipality).where("municipalities.name like ?", "malmö%").count,
      deregistered: collection.where.not(deregistered: nil).count,
      drafts: collection.where(draft: true).count,
      duplicates: collection.includes(:relationships).where('relationships.type_of_relationship_id' => 1).count,
      top_countries: collection.joins(:countries).select('countries.name').group('countries.name').count('countries.name').sort_by{ |key, value| value }.reverse,
      top_languages: collection.joins(:languages).select('languages.name').group('languages.name').count('languages.name').sort_by{ |key, value| value }.reverse,
    }
  end

  def all_registered
    @all_registered ||= Refugee.all
  end

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

  def registered_last_week
    @registered_last_week ||=
      one_week_ago = Date.today - 1.week
      Refugee.where(registered: one_week_ago.beginning_of_week..one_week_ago.end_of_week)
  end

  def registered_per_date(date)
    Refugee.where(registered: date).count
  end

  def last_week_start
    Date.today.beginning_of_week - 7.days
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
