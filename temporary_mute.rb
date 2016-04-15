# -*- coding: utf-8 -*-

Plugin.create(:temporary_mute) do

  # 一時ミュートする時間(秒)
  UserConfig[:temporary_mute_seconds] ||= 1800 # 30分

  @muted_users = Set.new        # user_id

  command(:temporary_mute_user_add,
          name: "このユーザを一定時間をミュートする",
          condition: -> _ { true },
          visible: true,
          role: :timeline ) do |m|
              m.messages.each do |msg|
                  temporary_mute(msg.user,UserConfig[:temporary_mute_seconds])
              end
          end

  filter_show_filter do |messages|
    [messages.select{ |m| !@muted_users.include?(m.user.id) }]
  end

  on_temporary_mute_muted do |user,time|
    Plugin.call(:update, nil, [Message.new(:message => "@#{user.idname} を #{Time.now + time} までミュートします",
                                           :system => true)])
  end

  on_temporary_mute_unmuted do |user|
    Plugin.call(:update, nil, [Message.new(:message => "@#{user.idname}のミュートを解除します",
                                           :system => true)])
  end

  settings "temporary_mute" do
    adjustment "ミュートする時間(秒)", :temporary_mute_seconds, 1, 60 ** 2 * HYDE
  end

  class << self
    def temporary_mute(user, mute_limit)
      Plugin.call(:temporary_mute_muted, user, mute_limit)
      @muted_users << user.id
      Reserver.new(mute_limit){
        temporary_unmute(user) }
    end

    def temporary_unmute(user)
      Plugin.call(:temporary_mute_unmuted, user)
      @muted_users.delete(user.id) 
    end
  end

end

