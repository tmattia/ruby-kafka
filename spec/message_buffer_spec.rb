# frozen_string_literal: true

describe Kafka::MessageBuffer do
  let(:buffer) { Kafka::MessageBuffer.new }

  describe "#concat" do
    it "adds the messages to the buffer" do
      buffer.concat(["foo"], topic: "foo", partition: 0)

      expect(buffer.size).to eq 1
      expect(buffer.bytesize).to eq 3
    end

    it "handles empty arrays" do
      buffer.concat([], topic: "foo", partition: 0)

      expect(buffer.size).to eq 0
      expect(buffer.bytesize).to eq 0
    end
  end

  describe "#clear_messages" do
    it "clears messages for the given topic and partition" do
      buffer.concat(["yolo"], topic: "x", partition: 0)
      buffer.clear_messages(topic: "x", partition: 0)

      expect(buffer.size).to eq 0
    end

    it "handles clearing a topic that's not in the buffer" do
      buffer.clear_messages(topic: "x", partition: 0)

      expect(buffer.size).to eq 0
    end

    it "handles clearing a partition that's not in the buffer" do
      buffer.concat(["yolo"], topic: "x", partition: 0)
      buffer.clear_messages(topic: "x", partition: 1)

      expect(buffer.size).to eq 1
    end
  end

  describe "#size" do
    it "returns the number of messages in the buffer" do
      buffer.concat(["a", "b", "c"], topic: "bar", partition: 3)
      buffer.concat(["a", "b", "c"], topic: "bar", partition: 1)

      expect(buffer.size).to eq 6
    end

    it "keeps track of how many messages have been cleared" do
      buffer.concat(["a", "b", "c"], topic: "bar", partition: 3)
      buffer.concat(["a", "b", "c"], topic: "bar", partition: 1)
      buffer.clear_messages(topic: "bar", partition: 3)

      expect(buffer.size).to eq 3
    end

    it "buffers messages quickly", performance: true do
      num_topics = 20
      num_partitions = 20
      num_messages = 10_000

      (1...num_messages).each do |i|
        topic = num_topics % i
        partition = num_partitions % i

        buffer.write("hello", topic: topic, partition: partition)
      end

      expect { buffer.size }.to perform_at_least(10000).ips
    end
  end

  describe "#bytesize" do
    it "returns the bytesize of the messages in the buffer" do
      buffer.write(value: "foo", key: "bar", topic: "yolos", partition: 1)
      buffer.write(value: "baz", key: "bim", topic: "yolos", partition: 1)

      expect(buffer.bytesize).to eq 12
    end

    it "keeps track of concatenations" do
      message = Kafka::Protocol::Message.new(value: "baz", key: "bim")

      buffer.write(value: "foo", key: "bar", topic: "yolos", partition: 1)
      buffer.concat([message], topic: "yolos", partition: 1)

      expect(buffer.bytesize).to eq 12
    end

    it "keeps track of when messages are cleared" do
      buffer.write(value: "foo", key: "bar", topic: "yolos", partition: 1)
      buffer.write(value: "baz", key: "bim", topic: "yolos", partition: 2)

      buffer.clear_messages(topic: "yolos", partition: 1)

      expect(buffer.bytesize).to eq 6
    end

    it "is reset when #clear is called" do
      buffer.write(value: "baz", key: "bim", topic: "yolos", partition: 2)
      buffer.clear

      expect(buffer.bytesize).to eq 0
    end
  end
end
