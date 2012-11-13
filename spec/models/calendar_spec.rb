require "spec_helper.rb"

describe Calendar do
  it { should belong_to(:customer) }
  it { should belong_to(:holiday_calendar) }
  it { should have_many(:events) }

  it { should allow_mass_assignment_of(:title) }
  it { should allow_mass_assignment_of(:description) }
  it { should allow_mass_assignment_of(:country) }
  it { should_not allow_mass_assignment_of(:customer_id) }
  it { should_not allow_mass_assignment_of(:holiday_calendar_id) }

  it { should validate_presence_of(:title).on(:create, :update) }
  it { should validate_length_of(:title).within(1..40) }
  it { should validate_length_of(:description).within(0..1000) }

  context "holidays" do
    let!(:holiday_calendar) { create(:holiday_calendar) }
    let!(:calendar) { create(:calendar, country: holiday_calendar.country) }
    let!(:event) { create(:event, holiday_calendar: holiday_calendar) }

    it "should assign holiday calendar on create action" do
      calendar.holiday_calendar.country.should == calendar.country
    end
    
    it "should delegate holidays to holiday_calendar" do
      calendar.holidays.should == holiday_calendar.events
    end
  end
end

