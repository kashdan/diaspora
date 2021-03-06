require 'spec_helper'


describe NotificationsHelper do
  include ApplicationHelper
  before do
    @user = Factory(:user)
    @person = Factory(:person)
    @post = Factory(:status_message, :author => @user.person)
    @person2 = Factory(:person)
    @notification = Notification.notify(@user, Factory(:like, :author => @person, :target => @post), @person)
    @notification =  Notification.notify(@user, Factory(:like, :author => @person2, :target => @post), @person2)
  end

  describe '#notification_people_link' do
    context 'formatting' do
      include ActionView::Helpers::SanitizeHelper
      let(:output){ strip_tags(notification_people_link(@note)) }

      before do
        @max = Factory(:person)
        @max.profile.first_name = 'max'
        @max.profile.last_name = 'salzberg'
        @sarah = Factory(:person)
        @sarah.profile.first_name = 'sarah'
        @sarah.profile.last_name = 'mei'


        @daniel = Factory(:person)
        @daniel.profile.first_name = 'daniel'
        @daniel.profile.last_name = 'grippi'

        @ilya = Factory(:person)
        @ilya.profile.first_name = 'ilya'
        @ilya.profile.last_name = 'zhit'
        @note = mock()
      end

      it 'with two, does not comma seperate two actors' do
        @note.stub!(:actors).and_return([@max, @sarah])
        output.scan(/,/).should be_empty
        output.scan(/and/).count.should be 1
      end

      it 'with three, comma seperates the first two, and and the last actor' do
        @note.stub!(:actors).and_return([@max, @sarah, @daniel])
        output.scan(/,/).count.should be 2
        output.scan(/and/).count.should be 1
      end

      it 'with more than three, lists the first three, then the others tag' do
        @note.stub!(:actors).and_return([@max, @sarah, @daniel, @ilya])
        output.scan(/,/).count.should be 3
        output.scan(/and/).count.should be 2
      end
    end
    describe 'for a like' do
      it 'displays #{list of actors}' do
        output = notification_people_link(@notification)
        output.should include @person2.name
        output.should include @person.name
      end
    end
  end


  describe '#object_link' do
    describe 'for a like' do
      it 'should include a link to the post' do
        output = object_link(@notification, notification_people_link(@notification))
        output.should include post_path(@post)
      end

      it 'includes the boilerplate translation' do
        output = object_link(@notification, notification_people_link(@notification))
        output.should include t("#{@notification.popup_translation_key}.two",
                                :actors => notification_people_link(@notification),
                                :post_link => "<a href=\"#{post_path(@post)}\" class=\"hard_object_link\" data-ref=\"#{@post.id}\">#{t('notifications.post')}</a>")
      end

      context 'when post is deleted' do
        it 'works' do
          @post.destroy
          expect{ object_link(@notification, notification_people_link(@notification))}.should_not raise_error
        end

        it 'displays that the post was deleted' do
          @post.destroy
          object_link(@notification,  notification_people_link(@notification)).should == t('notifications.liked_post_deleted.one', :actors => notification_people_link(@notification))
        end
      end
    end
  end
end
