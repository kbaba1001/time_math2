describe TimeMath::Units::Base do
  def u(name)
    TimeMath::Units.get(name)
  end

  [Time, DateTime, Date].each do |t|
    describe "math with #{t}" do
      describe '#floor' do
        context 'default' do
          fixture = load_fixture(:floor, t)

          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "rounds down to #{step}" do
              expect(u(step).floor(source)).to eq t.parse(val)
            end
          end
        end

        context '#floor(3)' do
          fixture = load_fixture(:floor_3, t)

          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "rounds down to #{step}" do
              expect(u(step).floor(source, 3)).to eq t.parse(val)
            end
          end
        end

        context '#floor(1/2)' do
          fixture = load_fixture(:floor_half, t)

          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "rounds down to #{step}" do
              expect(u(step).floor(source, Rational(1, 2))).to eq t.parse(val)
            end
          end

          specify do
            unless t == Date
              expect(TimeMath.day.floor(t.parse('2016-06-22 11:14'), Rational(1, 2)))
                .to eq t.parse('2016-06-22 00:00')
              expect(TimeMath.day.floor(t.parse('2016-06-22 12:00'), Rational(1, 2)))
                .to eq t.parse('2016-06-22 12:00')
            end
          end
        end
      end

      describe '#ceil' do
        context 'default' do
          fixture = load_fixture(:ceil, t)

          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "rounds up to #{step}" do
              next if step == :day && t == Date
              expect(u(step).ceil(source)).to eq t.parse(val)
            end
          end
        end

        context '#ceil(3)' do
          fixture = load_fixture(:ceil_3, t)

          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "rounds up to #{step}" do
              expect(u(step).ceil(source, 3)).to eq t.parse(val)
            end
          end
        end

        context '#ceil(1/2)' do
          specify do
            expect(TimeMath.day.ceil(t.parse('2016-06-22 11:14'), Rational(1, 2)))
              .to eq t.parse('2016-06-22 12:00')
          end
        end
      end

      describe '#round' do
        context 'default' do
          let(:ceiled) { t.parse('2015-03-01 12:32') }
          let(:floored) { t.parse('2015-03-01 12:22') }
          let(:edge) { t.parse('2015-03-01 12:30') }

          let(:unit) { u(:hour) }

          it 'smartly rounds to ceil or floor' do
            expect(unit.round(ceiled)).to eq unit.ceil(ceiled)
            expect(unit.round(floored)).to eq unit.floor(floored)
            expect(unit.round(edge)).to eq unit.ceil(edge)
          end
        end

        context '#round(3)' do
          let(:ceiled) { t.parse('2015-03-01 14:32') }
          let(:floored) { t.parse('2015-03-01 12:22') }
          let(:edge) { t.parse('2015-03-01 13:30') }

          let(:unit) { u(:hour) }

          it 'smartly rounds to ceil or floor' do
            expect(unit.round(ceiled, 3)).to eq unit.ceil(ceiled, 3)
            expect(unit.round(floored, 3)).to eq unit.floor(floored, 3)
            expect(unit.round(edge, 3)).to eq unit.ceil(edge, 3)
          end
        end
      end

      describe '#prev' do
        let(:floored) { t.parse('2015-03-05') }
        let(:decreased) { t.parse('2015-03-01') }

        let(:unit) { u(:month) }

        it 'smartly calculates previous round' do
          expect(unit.prev(floored)).to eq unit.floor(floored)
          expect(unit.prev(decreased)).to eq unit.decrease(unit.floor(floored))
        end
      end

      describe '#next' do
        let(:ceiled) { t.parse('2015-03-05') }
        let(:advanced) { t.parse('2015-03-01') }

        let(:unit) { u(:month) }

        it 'smartly calculates next round' do
          expect(unit.next(ceiled)).to eq unit.ceil(ceiled)
          expect(unit.next(advanced)).to eq unit.advance(unit.floor(advanced))
        end
      end

      describe '#advance' do
        context 'one step' do
          fixture = load_fixture(:advance, t)
          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "advances one #{step} exactly" do
              expect(u(step).advance(source)).to eq t.parse(val)
            end
          end
        end

        context 'several steps' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          limit_units(%i[sec min hour day month year], t).each do |step|
            [3, 100, 1000].each do |amount|
              context "when advanced #{amount} #{step}s" do
                let(:unit) { u(step) }
                let(:correct) { amount.times.inject(tm) { |tt| unit.advance(tt) } }

                subject { unit.advance(tm, amount) }

                it { is_expected.to eq correct }
              end
            end
          end
        end

        context 'negative advance' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          limit_units(%i[sec min hour day month year], t).each do |step|
            context "when step=#{step}" do
              let(:unit) { u(step) }

              it 'treats negative advance as decrease' do
                expect(unit.advance(tm, -13)).to eq(unit.decrease(tm, 13))
              end
            end
          end
        end

        context 'zero advance' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          %i[sec min hour day month year].each do |step|
            context "when step=#{step}" do
              let(:unit) { u(step) }

              it 'does nothing on zero advance' do
                expect(unit.advance(tm, 0)).to eq tm
              end
            end
          end
        end

        context 'non-integer advance' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }
          let(:r) { Rational(1, 2) }

          if t != Date
            it { expect(u(:min).advance(tm, r)).to eq t.parse('2015-03-27 11:40:50') }
            it { expect(u(:hour).advance(tm, r)).to eq t.parse('2015-03-27 12:10:20') }
            it { expect(u(:day).advance(tm, r)).to eq t.parse('2015-03-27 23:40:20') }
            it { expect(u(:week).advance(tm, r)).to eq t.parse('2015-03-30 23:40:20') }
          else
            xit { expect(u(:week).advance(tm, r)).to eq t.parse('2015-03-30') }
          end

          it 'behaves when non-integer advance have no clear sense' do
            expect(u(:month).advance(tm, r)).to eq tm
            expect(u(:year).advance(tm, r)).to eq tm

            expect(u(:month).advance(tm, 1 + r)).to eq u(:month).advance(tm, 1)
            expect(u(:year).advance(tm, 1 + r)).to eq u(:year).advance(tm, 1)
          end
        end
      end

      describe '#decrease' do
        context 'one step' do
          fixture = load_fixture(:decrease, t)
          let(:source) { t.parse(fixture[:source]) }

          fixture[:targets].each do |step, val|
            it "decreases one #{step} exactly" do
              expect(u(step).decrease(source)).to eq t.parse(val)
            end
          end
        end

        context 'several steps' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          limit_units(%i[sec min hour day month year], t).each do |step|
            [3, 100, 1000].each do |amount|
              context "when decreased #{amount} #{step}s" do
                let(:unit) { u(step) }
                let(:correct) { amount.times.inject(tm) { |tt| unit.decrease(tt) } }

                subject { unit.decrease(tm, amount) }

                it { is_expected.to eq correct }
              end
            end
          end
        end

        context 'negative decrease' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          limit_units(%i[sec min hour day month year], t).each do |step|
            context "when step=#{step}" do
              let(:unit) { u(step) }

              it 'treats negative decrease as advance' do
                expect(unit.decrease(tm, -13)).to eq(unit.advance(tm, 13))
              end
            end
          end
        end

        context 'zero decrease' do
          let(:tm) { t.parse('2015-03-27 11:40:20') }

          %i[sec min hour day month year].each do |step|
            context "when step=#{step}" do
              let(:unit) { u(step) }

              it 'does nothing on zero decrease' do
                expect(unit.decrease(tm, 0)).to eq tm
              end
            end
          end
        end
      end

      describe '#round?' do
        let(:fixture) { load_fixture(:round, t) }

        it 'determines if tm is round to step' do
          fixture.each do |step, vals|
            expect(u(step).round?(t.parse(vals[:true]))).to be_truthy

            next if step == :day && t == Date # always round, you know :)

            expect(u(step).round?(t.parse(vals[:false]))).to be_falsy
          end
        end
      end

      describe '#range' do
        let(:from) { Time.now }

        limit_units(TimeMath::Units.names, t).each do |step|
          context "with step=#{step}" do
            let(:unit) { u(step) }

            context 'when single step' do
              subject { unit.range(from) }

              it { is_expected.to eq(from...unit.advance(from)) }
            end

            context 'when several steps' do
              subject { unit.range(from, 5) }

              it { is_expected.to eq(from...unit.advance(from, 5)) }
            end
          end
        end
      end

      describe '#range_back' do
        let(:from) { Time.now }

        limit_units(TimeMath::Units.names, t).each do |step|
          context "with step=#{step}" do
            let(:unit) { u(step) }

            context 'when single step' do
              subject { unit.range_back(from) }

              it { is_expected.to eq(unit.decrease(from)...from) }
            end

            context 'when several steps' do
              subject { unit.range_back(from, 5) }

              it { is_expected.to eq(unit.decrease(from, 5)...from) }
            end
          end
        end
      end

      describe '#measure' do
        fixture = load_fixture(:measure, t)

        fixture.each do |data|
          next if t == Date && data[:unit] == :year # problematic edge case, works but different from others
          context data[:unit] do
            let(:unit) { u(data[:unit]) }
            let(:from) { t.parse(data[:from]) }
            let(:to) { t.parse(data[:to]) }

            subject { unit.measure(from, to) }

            it { is_expected.to eq data[:val] }
          end
        end
      end

      describe '#measure_rem' do
        fixture = load_fixture(:measure, t)

        fixture.each do |data|
          next if t == Date && data[:unit] == :year # problematic edge case, works but different from others
          context data[:unit] do
            let(:unit) { u(data[:unit]) }
            let(:from) { t.parse(data[:from]) }
            let(:to) { t.parse(data[:to]) }

            it 'measures integer steps between from and to and return reminder' do
              measure, rem = unit.measure_rem(from, to)

              expected_rem = unit.advance(from, measure)

              expect(measure).to eq data[:val]
              expect(rem).to eq expected_rem
            end

            it 'is exactly the same for same data' do
              measure, rem = unit.measure_rem(to, to)
              expect(measure).to eq 0
              expect(rem).to eq to
            end

            it 'is correct for backwards measurement' do
              measure, rem = unit.measure_rem(to, from)
              expected_rem = unit.advance(to, measure)

              expect(measure).to eq(-data[:val])
              expect(rem).to eq expected_rem
            end
          end
        end
      end

      describe '#sequence' do
        let(:from) { t.parse('2016-05-01 13:30') }
        let(:to) { t.parse('2016-05-15 15:45') }

        limit_units(TimeMath.units, t).each do |unit|
          context "with #{unit}" do
            subject { u(unit).sequence(from...to) }

            it { is_expected.to eq TimeMath::Sequence.new(unit, from...to) }
          end
        end
      end
    end
  end

  describe '#resample' do
    let(:unit) { TimeMath.day }

    context 'array of time' do
      let(:data) { [Time.parse('2016-06-01'), Time.parse('2016-06-03'), Time.parse('2016-06-05')] }

      subject { unit.resample(data) }

      it {
        is_expected.to eq([
                            Time.parse('2016-06-01'),
                            Time.parse('2016-06-02'),
                            Time.parse('2016-06-03'),
                            Time.parse('2016-06-04'),
                            Time.parse('2016-06-05')
                          ])
      }
    end

    context 'hash with time keys' do
      let(:data) {
        {
          Time.parse('2016-06-01') => 1, Time.parse('2016-06-03') => 2, Time.parse('2016-06-05') => 3
        } }

      context 'no block' do
        subject { unit.resample(data) }

        it {
          is_expected.to eq(
            Time.parse('2016-06-01') => [1],
            Time.parse('2016-06-02') => [],
            Time.parse('2016-06-03') => [2],
            Time.parse('2016-06-04') => [],
            Time.parse('2016-06-05') => [3]
          )
        }
      end

      context 'block' do
        subject { unit.resample(data, &:first) }

        it {
          is_expected.to eq(
            Time.parse('2016-06-01') => 1,
            Time.parse('2016-06-02') => nil,
            Time.parse('2016-06-03') => 2,
            Time.parse('2016-06-04') => nil,
            Time.parse('2016-06-05') => 3
          )
        }
      end

      context 'symbol' do
        subject { unit.resample(data, :first) }

        it {
          is_expected.to eq(
            Time.parse('2016-06-01') => 1,
            Time.parse('2016-06-02') => nil,
            Time.parse('2016-06-03') => 2,
            Time.parse('2016-06-04') => nil,
            Time.parse('2016-06-05') => 3
          )
        }
      end
    end

    context 'wrong arguments' do
      let(:data) { [1, 2, 3] }

      it { expect { unit.resample(data) }.to raise_error(ArgumentError) }
    end
  end

  # TODO: edge cases:
  # * monthes decr/incr, including leap years
  describe 'edge cases' do
    specify 'advance over month end' do
      expect(TimeMath.month.advance(DateTime.new(2017, 5, 29), 9)).to eq DateTime.new(2018, 2, 28)
      expect(TimeMath.month.advance(Time.new(2017, 5, 29), 10)).to eq Time.new(2018, 3, 29)
    end
  end

  describe 'type compatibility' do
    let(:t) { Time.parse('2017-05-01 17:30') }
    let(:d) { Date.parse('2017-06-15') }
    let(:dt) { DateTime.parse('2017-03-10 15:40') }

    it { expect(TimeMath.month.measure(t, d)).to eq 1 }
    it { expect(TimeMath.month.measure(t, dt)).to eq(-1) }
    it { expect(TimeMath.month.measure(d, dt)).to eq(-3) }
  end

  describe 'Preserve time offset' do
    let(:tm) { Time.parse('2016-06-01 14:30 +08') }
    let(:day) { TimeMath.day }

    it 'preserves time offset always' do
      expect(day.floor(tm)).to eq(Time.parse('2016-06-01 00:00 +08')).and(have_attributes(gmt_offset: 8 * 3600))
      expect(day.ceil(tm)).to eq(Time.parse('2016-06-02 00:00 +08')).and(have_attributes(gmt_offset: 8 * 3600))
      expect(day.advance(tm)).to eq(Time.parse('2016-06-02 14:30 +08')).and(have_attributes(gmt_offset: 8 * 3600))
      expect(day.decrease(tm)).to eq(Time.parse('2016-05-31 14:30 +08')).and(have_attributes(gmt_offset: 8 * 3600))
    end
  end

  context 'graceful fail' do
    let(:unit) { u(:day) }

    it { expect { unit.advance('2016-05-01') }.to raise_error ArgumentError, /got String/ }
  end
end
