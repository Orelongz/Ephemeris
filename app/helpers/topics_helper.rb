module TopicsHelper
  class Topics < BaseHelper::Base
    def self.create(title, is_public, user_id)
      topic = Topic.new(title: title, is_public: is_public, user_id: user_id)
      if topic.save
        build_topic_response(topic)
      else
        ExceptionHandlerHelper::GQLCustomError.new(topic.errors.full_messages)
      end
    end

    def self.update(model, new_record)
      model.posts.update_all(is_public: new_record[:is_public]) unless new_record[:is_public]
      if model.update(new_record)
        build_topic_response(model)
      else
        ExceptionHandlerHelper::GQLCustomError.new(model.errors.full_messages)
      end
    end

    def self.destroy(topic_record)
      destroyed = topic_record.destroy
      build_topic_response(destroyed)
    end

    def self.fetch_with_relationship_by(type, *relationship)
      Topic.includes(relationship).find_by(type)
    end

    def self.build_topic_response(topic_record)
      {
        "topic": {
          "uuid": topic_record[:uuid],
          "title": topic_record[:title]
        }
      }
    end
  end
end
