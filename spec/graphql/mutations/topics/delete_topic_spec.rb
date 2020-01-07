require 'rails_helper'

module Mutations
  module Topics
    RSpec.describe DeleteTopic, type: :request do
      describe '.resolve' do
        token = nil
        topic_uuid = nil
        before(:all) do
          create(:user)
          post '/graphql', params: { query: login_mutation(dummy_login_credentials) }
          json = JSON.parse(response.body)
          token = json['data']['userLogin']['token']

          post '/graphql', params: { query: topic_mutation("createTopic", dummy_topic_credentials) },
               headers: { Authorization: token }
          json = JSON.parse(response.body)
          topic_uuid = json['data']['createTopic']['topic']['uuid']

          post '/graphql', params: { query: create_post_mutation(dummy_post_credentials(topic_uuid, "1st dummy post", nil)) },
               headers: { Authorization: token }
          post '/graphql', params: { query: create_post_mutation(dummy_post_credentials(topic_uuid, "2nd dummy post", nil)) },
               headers: { Authorization: token }
        end

        after(:all) do
          User.destroy_all
        end

        it 'should not successfully delete a topic without token' do
          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials('first delete test', false, topic_uuid)) }
          json = JSON.parse(response.body)
          error = json['errors'][0]
          expect(error).to include( "message" => MessagesHelper::Auth.token_verification_error )
        end

        it 'should not delete a topic with an invalid token' do
          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials('second delete test', false, topic_uuid)) },
               headers: { Authorization: fake_token }
          json = JSON.parse(response.body)
          errors = json["errors"]
          expect(errors).to include(
                              "message" => MessagesHelper::Auth.invalid_token
                            )
        end

        it 'should not delete a topic with an expired token' do
          expired_token = 'eyJhbGciOiJIUzI1NiJ9.eyJ1dWlkIjoiMzc5OTAyYzEtMjczYy00Y2U2LWJkODMtNzQyMTNkMzI4MzkwIiwiZXhwIjoxNTc3MjE4MjQ1fQ.dhrjEf3JNf9Pa9YJXdzpAVcH9jitIsNdNOnCo7IqxJS'
          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials('third update test', false, topic_uuid)) },
               headers: { Authorization: fake_token(expired_token) }
          json = JSON.parse(response.body)
          errors = json["errors"]
          expect(errors).to include(
                              "message" => MessagesHelper::Auth.expired_token
                            )
        end

        it 'should return User unauthorized error if a user tries to delete topic(s) belonging to other users' do
          user_obj = { name: 'alt_user', screen_name: 'alt_user_p', email: 'alt_user@test.com',
                       password: '1234567890', password_confirmation: '1234567890' }
          create(:user, user_obj)
          post '/graphql', params: { query: login_mutation(dummy_login_credentials(user_obj[:email], user_obj[:password])) }
          json = JSON.parse(response.body)
          local_token = json['data']['userLogin']['token']

          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials("Fourth update test", false, topic_uuid)) },
               headers: { Authorization: local_token }
          json = JSON.parse(response.body)
          error = json['errors'][0]

          expect(error).to include( "message" => MessagesHelper::Auth.user_unauthorized )
        end

        it 'should return not found error if non-existing uuid is supplied' do
          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials('', false, '')) },
               headers: { Authorization: token }
          json = JSON.parse(response.body)
          error = json['errors'][0]
          expect(error).to include( "message" => MessagesHelper::Resource.not_found(TopicsHelper::Topics.resource_name))
        end

        it 'should successfully delete a topic with right credentials supplied' do
          post '/graphql', params: { query: topic_mutation("deleteTopic", dummy_topic_credentials('', false, topic_uuid)) },
               headers: { Authorization: token }
          json = JSON.parse(response.body)
          topic = json['data']['deleteTopic']['topic']
          expect(topic).to include(
                             "uuid" => be_present,
                             "title" => dummy_topic_credentials[:title]
                           )
        end
      end
    end
  end
end
