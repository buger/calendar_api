require "spec_helper"

describe Customer do
  it { should have_many(:calendars) }
  it { should have_index_for(api_key: 1).with_options(unique: true) }
  it { should_not allow_mass_assignment_of(:api_key) }
end

