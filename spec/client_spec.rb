# frozen_string_literal: true

describe Kafka::Client do
  let(:logger) { LOGGER }
  let(:kafka_brokers) { KAFKA_BROKERS }
  let(:client_opts) do
    {
      seed_brokers: KAFKA_BROKERS,
      client_id: "test",
      logger: logger
    }
  end

  describe ".new" do
    context "when SASL SCRAM has been configured without ssl" do
      before do
        client_opts.update({
          sasl_scram_username: "spec_username",
          sasl_scram_password: "spec_password",
          sasl_scram_mechanism: "sha256"
        })
      end
      context "when sasl_over_ssl is unspecified" do
        it "raises ArgumentError due to missing SSL config" do
          expect {
            described_class.new(client_opts)
          }.to raise_error(ArgumentError, /SASL authentication requires that SSL is configured/)
        end
      end

      context "when sasl_over_ssl is true" do
        before { client_opts.update(sasl_over_ssl: true) }

        it "raises ArgumentError due to missing SSL config" do
          expect {
            described_class.new(client_opts)
          }.to raise_error(ArgumentError, /SASL authentication requires that SSL is configured/)
        end
      end

      context "when sasl_over_ssl is false" do
        before { client_opts.update(sasl_over_ssl: false) }

        it "creates a new Kafka::Client object" do
          expect { described_class.new(client_opts) }.to_not raise_exception
        end
      end
    end
  end
end
