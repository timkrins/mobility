require "spec_helper"
require "mobility/plugins/fallbacks"

describe Mobility::Plugins::Fallbacks, type: :plugin do
  plugin_setup

  context "fallbacks is a hash" do
    plugins do
      fallbacks({ :'en-US' => 'de-DE', :pt => 'de-DE' })
    end

    it "returns value when value is not nil" do
      allow(listener).to receive(:read).once.with(:ja, any_args).and_return("ja val")
      expect(backend.read(:ja)).to eq("ja val")
    end

    it "falls through to fallback locale when value is nil" do
      allow(listener).to receive(:read).exactly(3).times do |locale|
        { :'en-US' => nil, :en => nil, :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(backend.read(:'en-US')).to eq("de val")
    end

    it "falls through to fallback locale when value is blank" do
      allow(listener).to receive(:read).exactly(3).times do |locale|
        { :'en-US' => '', :en => '', :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(backend.read(:'en-US')).to eq("de val")
    end

    it "returns backend value when no fallback is found" do
      expect(listener).to receive(:read).exactly(5).times do |locale|
        { :'en-US' => '', :en => '', :'de-DE' => nil, :de => nil }.fetch(locale)
      end
      expect(backend.read(:'en-US')).to eq('')
    end

    it "returns backend value when fallback: false option is passed" do
      expect(listener).to receive(:read).once.with(:'en-US', any_args).and_return('')
      expect(backend.read(:'en-US', fallback: false)).to eq('')
    end

    it "falls through to fallback locale when fallback: true option is passed" do
      expect(listener).to receive(:read).exactly(2).times do |locale|
        { :'en-US' => '', :en => 'en val' }.fetch(locale)
      end
      expect(backend.read(:'en-US', fallback: true)).to eq("en val")
    end

    it "uses locale passed in as value of fallback option when present" do
      expect(listener).to receive(:read).exactly(2).times do |locale|
        { :'en-US' => '', :ja => 'ja val' }.fetch(locale)
      end
      expect(backend.read(:'en-US', fallback: :ja)).to eq("ja val")
    end

    it "uses locale passed in to with_fallbacks_override as value of fallback option when present" do
      expect(listener).to receive(:read).exactly(2).times do |locale|
        { :'en-US' => '', :ja => 'ja val' }.fetch(locale)
      end
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override(:ja) { backend.read(:'en-US') }).to eq("ja val")
    end

    it "uses array of locales passed in as value of fallback options when present" do
      expect(listener).to receive(:read).exactly(2).times do |locale|
        { :'en-US' => '', :pl => 'pl val', :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(backend.read(:"en-US", fallback: [:pl, :'de-DE'])).to eq("pl val")
    end

    it "uses array of locales passed to with_fallbacks_override as value of fallback options when present" do
      expect(listener).to receive(:read).exactly(2).times do |locale|
        { :'en-US' => '', :pl => 'pl val', :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override([:pl, :'de-DE']) { backend.read(:"en-US") }).to eq("pl val")
    end

    it "passes options to getter in fallback locale" do
      expect(listener).to receive(:read).once.with(:'en-US', foo: true).and_return("bar")
      expect(backend.read(:'en-US', foo: true)).to eq("bar")
    end

    it "does not modify options passed in" do
      options = { fallback: false }
      allow(listener).to receive(:read).once
      backend.read(:'en-US', **options)
      expect(options).to eq({ fallback: false })
    end
  end

  if ENV['FEATURE'] == 'i18n_fallbacks'
    context "fallbacks is default" do
      plugins do
        fallbacks
      end

      it "uses default fallbacks" do
        i18n_fallbacks = I18n.fallbacks
        I18n.fallbacks = I18n::Locale::Fallbacks.new
        I18n.fallbacks.map('en-US' => ['ja'])
        allow(listener).to receive(:read) do |locale|
          { :'en-US' => '', :en => '', :ja => 'ja val' }.fetch(locale)
        end
        expect(backend.read(:'en-US')).to eq('ja val')
        I18n.fallbacks = i18n_fallbacks
      end
    end
  end

  context "fallbacks is nil" do
    plugins do
      fallbacks nil
    end

    it "does not use fallbacks when accessor fallback option is false or nil" do
      expect(listener).to receive(:read).with(:'en-US', any_args).once.and_return('')
      expect(backend.read(:'en-US')).to eq('')
      expect(listener).to receive(:read).with(:'en-US', any_args).once.and_return('')
      expect(backend.read(:'en-US', fallback: false)).to eq('')
    end

    it "uses locale passed in as value of fallback option when present" do
      allow(listener).to receive(:read) do |locale|
        { :'en-US' => '', :en => '', :ja => 'ja val' }.fetch(locale)
      end
      expect(backend.read(:"en-US", fallback: :ja)).to eq('ja val')
    end

    it "uses locale passed to with_fallbacks_override as value of fallback option when present" do
      allow(listener).to receive(:read) do |locale|
        { :'en-US' => '', :en => '', :ja => 'ja val' }.fetch(locale)
      end
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override(:ja) { backend.read(:"en-US") }).to eq('ja val')
    end

    it "uses array of locales passed in as value of fallback options when present" do
      expect(listener).to receive(:read).exactly(4).times do |locale|
        { :'en-US' => '', :pl => 'pl val', :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(backend.read(:'en-US', fallback: [:pl, :'de-DE'])).to eq('pl val')
      expect(backend.read(:'en-US', fallback: [:'de-DE', :pl])).to eq('de val')
    end

    it "uses array of locales passed to with_fallbacks_override as value of fallback options when present" do
      expect(listener).to receive(:read).exactly(4).times do |locale|
        { :'en-US' => '', :pl => 'pl val', :'de-DE' => 'de val' }.fetch(locale)
      end
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override([:pl, :'de-DE']) { backend.read(:'en-US') }).to eq('pl val')
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override([:'de-DE', :pl]) { backend.read(:'en-US') }).to eq('de val')
    end

    it "does not use fallbacks when fallback: true option is passed" do
      expect(listener).to receive(:read).once.with(:'en-US', any_args).and_return(nil)
      expect(backend.read(:'en-US', fallback: true)).to eq(nil)
    end

    it "does not use fallbacks when fallback: true option is passed to with_fallbacks_override" do
      expect(listener).to receive(:read).once.with(:'en-US', any_args).and_return(nil)
      expect(Mobility::Plugins::Fallbacks.with_fallbacks_override(true) { backend.read(:'en-US') }).to eq(nil)
    end
  end

  # We've taken away the ability to customize the fallbacks generator from
  # configuration, but it is still possible by overriding a private method on
  # the Translations class.
  describe "overriding fallbacks generator" do
    plugins do
      fallbacks
    end

    before do
      translations_class.class_eval do
        private

        def generate_fallbacks(_)
          Hash.new([])
        end
      end
    end

    it "uses overridden fallbacks generator" do
      expect(listener).to receive(:read).once.with(:'en-US', any_args).and_return(nil)
      expect(backend.read(:'en-US', fallback: true)).to eq(nil)
    end
  end
end
