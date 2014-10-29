package PostSlackOnSaving::L10N::ja;

use strict;
use base 'PostSlackOnSaving::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
    # config.yaml
    'bit part LLC' => 'bit part 合同会社',
    'Post a message to Slack when an author data is updated.' => 'ユーザー情報が更新されたときにSlackにポストします。',

    # Plugin.pm
    'A User have been updated.' => 'ユーザー情報が更新されました。',

    # config_template.tmpl
    'Slack API URL' => '',
    'Token' => 'トークン',
    'Channel' => 'チャンネル',
    'User name' => '投稿者名',
    'Icon URL' => 'アイコンURL',
    'Response' => 'レスポンス',
    'Nothing to do' => '何もしない',
    'Save the response to system log.' => 'システムログに保存する',
);

1;
