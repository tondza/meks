FactoryGirl.define do
  factory :ssn do
    refugee { create(:refugee) }
    date_of_birth { Date.today - 4.years - rand(16).years }
    extension { rand(1000..9999) }
  end
end
