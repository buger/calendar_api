require "spec_helper.rb"

describe HolidayCalendar do
  it { should have_fields(:country).of_type(String) }
  it { should allow_mass_assignment_of(:country) }
  it { should validate_presence_of(:country).on(:create, :update) }
  it { should have_index_for(country: 1).with_options(unique: true) }
  it { should have_many(:events) }
  it { should belong_to(:customer) }
end

