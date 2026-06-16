# frozen_string_literal: true

require 'ephesus/core/formats/plain_text/format_message'

RSpec.describe Ephesus::Core::Formats::PlainText::FormatMessage do
  subject(:command) { described_class.new(**options) }

  deferred_context 'when initialized with a registry' do
    let(:messages_scope) do
      if defined?(scope)
        next "#{scope}.spec.notifications" unless scope.is_a?(Proc)

        next scope.call('spec.notifications')
      end

      'spec.notifications'
    end
    let(:messages_templates) do
      {}
    end
    let(:strategy) do
      # @todo: Convert this to a class constant on FormatMessage.
      validate_values = lambda do |value|
        # :nocov:
        return if value == false || value == true # rubocop:disable Style/MultipleComparison
        return if value.is_a?(Numeric)
        return if value.is_a?(String) && !value.empty?

        # @todo: Register this as a message.
        'value must be true, false, an Integer, a Float, or a non-empty String'
        # :nocov:
      end

      SleepingKingStudios::Tools::Messages::Strategies::HashStrategy.new(
        messages_templates,
        flatten_templates: false,
        validate_values:
      )
    end
    let(:registry) do
      SleepingKingStudios::Tools::Messages::Registry
        .new
        .register(strategy:, scope: messages_scope)
    end
    let(:options) { super().merge(registry:) }
  end

  deferred_context 'when initialized with a scope' do
    let(:scope)   { 'spec' }
    let(:options) { super().merge(scope:) }
  end

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:registry, :scope)
    end
  end

  describe '#call' do
    deferred_examples 'should generate the template' do
      context 'when the template is a plain String' do
        let(:custom_template) { 'plain String value' }
        let(:expected_value)  { 'plain String value' }

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      context 'when the template is a String with missing wildcards' do
        let(:custom_template) { 'missing %<wildcard>s value' }
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'missing parameter :wildcard',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a String with valid wildcards' do
        let(:notification_data) { { wildcard: '(wildcard)' } }
        let(:custom_template)   { 'valid %<wildcard>s value' }
        let(:expected_value)    { 'valid (wildcard) value' }

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end
    end

    deferred_examples 'should generate the template from the Hash' do
      include_deferred 'should generate the template'

      context 'when the template Hash has plain String values' do
        let(:notification_data) do
          {
            'ability_name' => 'Jump Scare',
            'monster_name' => 'G-g-g-g-ghost'
          }
        end
        let(:template) do
          template =
            '%<monster_name>s used %<ability_name>s - %<exclamation>s!'

          {
            'exclamation' => 'Spooky',
            'template'    => template
          }
        end
        let(:expected_value) do
          'G-g-g-g-ghost used Jump Scare - Spooky!'
        end

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end
      end

      context 'when the template Hash has a String with missing wildcards' do
        let(:notification_data) do
          {
            'ability_name' => 'Jump Scare',
            'monster_name' => 'G-g-g-g-ghost'
          }
        end
        let(:template) do
          template =
            '%<monster_name>s used %<ability_name>s - %<exclamation>s!'

          {
            'exclamation' => 'It was %<effectiveness> effective!',
            'template'    => template
          }
        end
        let(:expected_error) do
          details =
            'missing parameter :effectiveness in template parameter ' \
            ':exclamation'

          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:,
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template Hash has a String with valid wildcards' do
        let(:notification_data) do
          {
            'ability_name'  => 'Jump Scare',
            'monster_name'  => 'G-g-g-g-ghost',
            'effectiveness' => 'super'
          }
        end
        let(:template) do
          template =
            '%<monster_name>s used %<ability_name>s - %<exclamation>s!'

          {
            'exclamation' => 'It was %<effectiveness>s effective',
            'template'    => template
          }
        end
        let(:expected_value) do
          'G-g-g-g-ghost used Jump Scare - It was super effective!'
        end

        it 'should return a passing result' do
          expect(command.call(notification))
            .to be_a_passing_result
            .with_value(expected_value)
        end

        context 'when the notification has a matching nil value' do
          let(:notification_data) do
            super().merge('exclamation' => nil)
          end

          it 'should return a passing result' do
            expect(command.call(notification))
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        context 'when the notification wildcards overwrite the template' do
          let(:notification_data) do
            super().merge('exclamation' => 'Nothing happened')
          end
          let(:expected_value) do
            'G-g-g-g-ghost used Jump Scare - Nothing happened!'
          end

          it 'should return a passing result' do
            expect(command.call(notification))
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end
      end

      context 'when the template Hash has a path String' do
        let(:notification_data) do
          {
            'ability_name' => 'Jump Scare',
            'monster_name' => 'G-g-g-g-ghost'
          }
        end
        let(:template) do
          template =
            '%<monster_name>s used %<ability_name>s - %<exclamation>s!'

          {
            'exclamation' => 'combat.descriptions.not_very_effective',
            'template'    => template
          }
        end

        context 'when the requested template is not found' do
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
              details:      'no strategy matches requested key',
              expected_key: 'combat.descriptions.not_very_effective',
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        context 'when the requested template is found' do
          let(:other_templates) do
            {
              'combat' => {
                'descriptions' => {
                  'not_very_effective' => "It's not very effective"
                }
              }
            }
          end
          let(:registry) do
            super().register(scope: 'combat', hash: other_templates)
          end
          let(:expected_value) do
            "G-g-g-g-ghost used Jump Scare - It's not very effective!"
          end

          it 'should return a passing result' do
            expect(command.call(notification))
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end

        context 'when the requested template has missing wildcards' do
          let(:other_templates) do
            {
              'combat' => {
                'descriptions' => {
                  'not_very_effective' => 'It was %<effectiveness> effective!'
                }
              }
            }
          end
          let(:registry) do
            super().register(scope: 'combat', hash: other_templates)
          end
          let(:expected_error) do
            details =
              'missing parameter :effectiveness in template parameter ' \
              ':exclamation'

            Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
              details:,
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        context 'when the requested template has valid wildcards' do
          let(:other_templates) do
            {
              'combat' => {
                'descriptions' => {
                  'not_very_effective' => 'It was %<effectiveness>s effective'
                }
              }
            }
          end
          let(:registry) do
            super().register(scope: 'combat', hash: other_templates)
          end
          let(:notification_data) do
            {
              'ability_name'  => 'Jump Scare',
              'monster_name'  => 'G-g-g-g-ghost',
              'effectiveness' => 'super'
            }
          end

          let(:expected_value) do
            'G-g-g-g-ghost used Jump Scare - It was super effective!'
          end

          it 'should return a passing result' do
            expect(command.call(notification))
              .to be_a_passing_result
              .with_value(expected_value)
          end
        end
      end
    end

    deferred_examples 'should generate the user-scoped template' do
      context 'when the template is a String value' do
        let(:template) { custom_template }

        include_deferred 'should generate the template'
      end

      context 'when the template is an empty Hash' do
        let(:template) { {} }
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'hash is missing key "template"',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a Hash with invalid properties' do
        let(:template) { { 'key' => 'value' } }
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'hash is missing key "template"',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a Hash with "template" key' do
        let(:template) { { 'template' => custom_template } }

        include_deferred 'should generate the template from the Hash'
      end
    end

    let(:original_actor)    { Ephesus::Core::Actor.new }
    let(:current_actor)     { original_actor }
    let(:notification_data) { {} }
    let(:notification) do
      Spec::Notifications::CustomNotification
        .new(current_actor:, original_actor:, **notification_data)
    end

    example_constant 'Spec::Notifications::CustomNotification' do
      Ephesus::Core::Messages::Notification.define(*notification_data.keys)
    end

    it { expect(command).to be_callable.with(1).argument }

    it 'should request the template from the registry' do
      allow(command.registry).to receive(:get)

      command.call(notification)

      expect(command.registry).to have_received(:get)
    end

    context 'when there is no matching strategy for the template' do
      let(:expected_error) do
        Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
          details:      'no strategy matches requested key',
          expected_key: notification.type,
          notification:
        )
      end

      it 'should return a failing result' do
        expect(command.call(notification))
          .to be_a_failing_result
          .with_error(expected_error)
      end
    end

    wrap_deferred 'when initialized with a registry' do
      context 'when there is no matching strategy for the template' do
        let(:notification) { Ephesus::Core::Message.new }
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
            details:      'no strategy matches requested key',
            expected_key: notification.type,
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the requested template is not defined' do
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
            details:      'template not defined',
            expected_key: notification.type,
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is an invalid object' do
        let(:custom_template) { 12_345 }
        let(:messages_templates) do
          {
            'spec' => {
              'notifications' => {
                'custom' => custom_template
              }
            }
          }
        end
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'template is not a Hash or a String',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a String value' do
        let(:messages_templates) do
          {
            'spec' => {
              'notifications' => {
                'custom' => custom_template
              }
            }
          }
        end

        include_deferred 'should generate the template'
      end

      context 'when the template is an empty Hash' do
        let(:messages_templates) do
          {
            'spec' => {
              'notifications' => {
                'custom' => {}
              }
            }
          }
        end
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'hash is missing key "template"',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a Hash with invalid properties' do
        let(:template) { { 'key' => 'value' } }
        let(:messages_templates) do
          {
            'spec' => {
              'notifications' => {
                'custom' => template
              }
            }
          }
        end
        let(:expected_error) do
          Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
            details:      'hash is missing key "template"',
            notification:
          )
        end

        it 'should return a failing result' do
          expect(command.call(notification))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the template is a Hash with "template" key' do
        let(:template) { { 'template' => custom_template } }
        let(:messages_templates) do
          {
            'spec' => {
              'notifications' => {
                'custom' => template
              }
            }
          }
        end

        include_deferred 'should generate the template from the Hash'
      end

      # rubocop:disable RSpec/NestedGroups
      context 'when the notification is for the current actor' do
        context 'when the template is a Hash with "agent" key' do
          let(:grouped_templates) { { 'agent' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the original actor is an agent' do
            let(:original_actor) { Ephesus::Core::Actor.new(user: false) }

            context 'when the template is false' do
              let(:template)       { false }
              let(:expected_value) { false }

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end

              context 'when a fallback "other" template is defined' do
                let(:grouped_templates) do
                  super().merge({ 'other' => 'Skipped template' })
                end

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end
            end

            include_deferred 'should generate the user-scoped template'
          end

          context 'when the original actor is a user' do
            let(:original_actor) { Ephesus::Core::Actor.new(user: true) }
            let(:template)       { 'Agent template' }
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
                details:      'hash is missing key "template"',
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end

            context 'when a fallback "other" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'Other template' })
              end
              let(:expected_value) { 'Other template' }

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end
            end
          end
        end

        context 'when the template is a Hash with "self" key' do
          let(:grouped_templates) { { 'self' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end

            context 'when a fallback "agent" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'Skipped template' })
              end

              context 'when the original actor is an agent' do
                let(:original_actor) { Ephesus::Core::Actor.new(user: false) }

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end

              context 'when the original actor is a user' do
                let(:original_actor) { Ephesus::Core::Actor.new(user: true) }

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end
            end

            context 'when a fallback "other" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'Skipped template' })
              end

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end
            end

            context 'when a fallback "user" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'user' => 'Skipped template' })
              end

              context 'when the original actor is an agent' do
                let(:original_actor) { Ephesus::Core::Actor.new(user: false) }

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end

              context 'when the original actor is a user' do
                let(:original_actor) { Ephesus::Core::Actor.new(user: true) }

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end
            end
          end

          include_deferred 'should generate the user-scoped template'
        end

        context 'when the template is a Hash with "other" key' do
          let(:grouped_templates) { { 'other' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end

          include_deferred 'should generate the user-scoped template'
        end

        context 'when the template is a Hash with "user" key' do
          let(:grouped_templates) { { 'user' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the original actor is an agent' do
            let(:original_actor) { Ephesus::Core::Actor.new(user: false) }
            let(:template)       { 'User template' }
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
                details:      'hash is missing key "template"',
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end

            context 'when a fallback "other" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'User template' })
              end
              let(:expected_value) { 'User template' }

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end
            end
          end

          context 'when the original actor is a user' do
            let(:original_actor) { Ephesus::Core::Actor.new(user: true) }

            context 'when the template is false' do
              let(:template)       { false }
              let(:expected_value) { false }

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end

              context 'when a fallback "other" template is defined' do
                let(:grouped_templates) do
                  super().merge({ 'other' => 'Skipped template' })
                end

                it 'should return a passing result' do
                  expect(command.call(notification))
                    .to be_a_passing_result
                    .with_value(expected_value)
                end
              end
            end

            include_deferred 'should generate the user-scoped template'
          end
        end
      end

      context 'when the notification is for a non-self agent' do
        let(:original_actor) { Ephesus::Core::Actor.new(user: false) }
        let(:current_actor)  { Ephesus::Core::Actor.new(user: true) }

        context 'when the template is a Hash with "agent" key' do
          let(:grouped_templates) { { 'agent' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end

            context 'when a fallback "other" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'Skipped template' })
              end

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end
            end
          end

          include_deferred 'should generate the user-scoped template'
        end

        context 'when the template is a Hash with "self" key' do
          let(:template)          { 'Self template' }
          let(:grouped_templates) { { 'self' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
              details:      'hash is missing key "template"',
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          context 'when a fallback "other" template is defined' do
            let(:grouped_templates) do
              super().merge({ 'other' => 'Other template' })
            end
            let(:expected_value) { 'Other template' }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end
        end

        context 'when the template is a Hash with "other" key' do
          let(:grouped_templates) { { 'other' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end

          include_deferred 'should generate the user-scoped template'
        end

        context 'when the template is a Hash with "user" key' do
          let(:template)          { 'User template' }
          let(:grouped_templates) { { 'user' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
              details:      'hash is missing key "template"',
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          context 'when a fallback "other" template is defined' do
            let(:grouped_templates) do
              super().merge({ 'other' => 'Other template' })
            end
            let(:expected_value) { 'Other template' }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end
        end
      end

      context 'when the notification is for a non-self user' do
        let(:original_actor) { Ephesus::Core::Actor.new(user: true) }
        let(:current_actor)  { Ephesus::Core::Actor.new(user: true) }

        context 'when the template is a Hash with "agent" key' do
          let(:template)          { 'Agent template' }
          let(:grouped_templates) { { 'agent' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
              details:      'hash is missing key "template"',
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          context 'when a fallback "other" template is defined' do
            let(:grouped_templates) do
              super().merge({ 'other' => 'Other template' })
            end
            let(:expected_value) { 'Other template' }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end
        end

        context 'when the template is a Hash with "self" key' do
          let(:template)          { 'Self template' }
          let(:grouped_templates) { { 'self' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::InvalidTemplate.new(
              details:      'hash is missing key "template"',
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end

          context 'when a fallback "other" template is defined' do
            let(:grouped_templates) do
              super().merge({ 'other' => 'Other template' })
            end
            let(:expected_value) { 'Other template' }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end
        end

        context 'when the template is a Hash with "other" key' do
          let(:grouped_templates) { { 'other' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end
          end

          include_deferred 'should generate the user-scoped template'
        end

        context 'when the template is a Hash with "user" key' do
          let(:grouped_templates) { { 'user' => template } }
          let(:messages_templates) do
            {
              'spec' => {
                'notifications' => {
                  'custom' => grouped_templates
                }
              }
            }
          end

          context 'when the template is false' do
            let(:template)       { false }
            let(:expected_value) { false }

            it 'should return a passing result' do
              expect(command.call(notification))
                .to be_a_passing_result
                .with_value(expected_value)
            end

            context 'when a fallback "other" template is defined' do
              let(:grouped_templates) do
                super().merge({ 'other' => 'Skipped template' })
              end

              it 'should return a passing result' do
                expect(command.call(notification))
                  .to be_a_passing_result
                  .with_value(expected_value)
              end
            end
          end

          include_deferred 'should generate the user-scoped template'
        end
      end
      # rubocop:enable RSpec/NestedGroups

      context 'when initialized with scope: a Proc' do
        let(:scope) do
          ->(key) { "messages.#{key}" }
        end
        let(:options) { super().merge(scope:) }

        context 'when there is no matching strategy for the template' do
          let(:notification) { Ephesus::Core::Message.new }
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
              details:      'no strategy matches requested key',
              expected_key: scope.call(notification.type),
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        # rubocop:disable RSpec/NestedGroups
        wrap_deferred 'when initialized with a registry' do
          context 'when there is no matching strategy for the template' do
            let(:notification) { Ephesus::Core::Message.new }
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'no strategy matches requested key',
                expected_key: scope.call(notification.type),
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the requested template is not defined' do
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'template not defined',
                expected_key: scope.call(notification.type),
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the template is a String value' do
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => custom_template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template'
          end

          context 'when the template is a Hash with "template" key' do
            let(:template) { { 'template' => custom_template } }
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template from the Hash'
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      context 'when initialized with scope: a String' do
        let(:scope)   { 'messages' }
        let(:options) { super().merge(scope:) }

        context 'when there is no matching strategy for the template' do
          let(:notification) { Ephesus::Core::Message.new }
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
              details:      'no strategy matches requested key',
              expected_key: "#{scope}.#{notification.type}",
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        # rubocop:disable RSpec/NestedGroups
        wrap_deferred 'when initialized with a registry' do
          context 'when there is no matching strategy for the template' do
            let(:notification) { Ephesus::Core::Message.new }
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'no strategy matches requested key',
                expected_key: "#{scope}.#{notification.type}",
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the requested template is not defined' do
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'template not defined',
                expected_key: "#{scope}.#{notification.type}",
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the template is a String value' do
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => custom_template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template'
          end

          context 'when the template is a Hash with "template" key' do
            let(:template) { { 'template' => custom_template } }
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template from the Hash'
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      context 'when initialized with scope: a Symbol' do
        let(:scope)   { :messages }
        let(:options) { super().merge(scope:) }

        context 'when there is no matching strategy for the template' do
          let(:notification) { Ephesus::Core::Message.new }
          let(:expected_error) do
            Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
              details:      'no strategy matches requested key',
              expected_key: "#{scope}.#{notification.type}",
              notification:
            )
          end

          it 'should return a failing result' do
            expect(command.call(notification))
              .to be_a_failing_result
              .with_error(expected_error)
          end
        end

        # rubocop:disable RSpec/NestedGroups
        wrap_deferred 'when initialized with a registry' do
          context 'when there is no matching strategy for the template' do
            let(:notification) { Ephesus::Core::Message.new }
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'no strategy matches requested key',
                expected_key: "#{scope}.#{notification.type}",
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the requested template is not defined' do
            let(:expected_error) do
              Ephesus::Core::Formats::PlainText::Errors::TemplateNotFound.new(
                details:      'template not defined',
                expected_key: "#{scope}.#{notification.type}",
                notification:
              )
            end

            it 'should return a failing result' do
              expect(command.call(notification))
                .to be_a_failing_result
                .with_error(expected_error)
            end
          end

          context 'when the template is a String value' do
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => custom_template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template'
          end

          context 'when the template is a Hash with "template" key' do
            let(:template) { { 'template' => custom_template } }
            let(:messages_templates) do
              {
                'messages' => {
                  'spec' => {
                    'notifications' => {
                      'custom' => template
                    }
                  }
                }
              }
            end

            include_deferred 'should generate the template from the Hash'
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end
  end

  describe '#registry' do
    let(:expected) { SleepingKingStudios::Tools::Messages::Registry.global }

    include_examples 'should define reader', :registry, -> { expected }

    wrap_deferred 'when initialized with a registry' do
      it { expect(command.registry).to be registry }
    end
  end

  describe '#scope' do
    include_examples 'should define reader', :scope, nil

    wrap_deferred 'when initialized with a scope' do
      it { expect(command.scope).to be == scope }

      context 'when the scope is a symbol' do
        let(:scope)    { :'spec.notifications' }
        let(:expected) { 'spec.notifications' }

        it { expect(command.scope).to be == expected }
      end

      context 'when the scope has a trailing period' do
        let(:scope)    { 'spec.notifications.' }
        let(:expected) { 'spec.notifications' }

        it { expect(command.scope).to be == expected }
      end
    end
  end
end
