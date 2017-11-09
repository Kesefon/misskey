<mk-channel-home-widget>
	<p class="title"><i class="fa fa-television"></i>{
		channel ? channel.title : '%i18n:desktop.tags.mk-channel-home-widget.title%'
	}</p>
	<button onclick={ settings } title="%i18n:desktop.tags.mk-channel-home-widget.settings%"><i class="fa fa-cog"></i></button>
	<mk-channel ref="channel"/>
	<style>
		:scope
			display block
			background #fff

			> .title
				z-index 2
				margin 0
				padding 0 16px
				line-height 42px
				font-size 0.9em
				font-weight bold
				color #888
				box-shadow 0 1px rgba(0, 0, 0, 0.07)

				> i
					margin-right 4px

			> button
				position absolute
				z-index 2
				top 0
				right 0
				padding 0
				width 42px
				font-size 0.9em
				line-height 42px
				color #ccc

				&:hover
					color #aaa

				&:active
					color #999

			> mk-channel
				height 200px

	</style>
	<script>
		this.mixin('i');
		this.mixin('api');

		this.channelId = this.opts.data.hasOwnProperty('channel') ? this.opts.data.channel : null;

		this.on('mount', () => {
			if (this.channelId) {
				this.zap();
			}
		});

		this.on('unmount', () => {

		});

		this.zap = () => {
			this.update({
				fetching: true
			});

			this.api('channels/show', {
				channel_id: this.channelId
			}).then(channel => {
				this.update({
					fetching: false,
					channel: channel
				});

				this.refs.channel.zap(channel);
			});
		};

		this.settings = () => {
			const id = window.prompt('チャンネルID');
			if (!id) return;
			this.channelId = id;
			this.zap();

			// Save state
			this.I.client_settings.home.filter(w => w.id == this.opts.id)[0].data.channel = this.channelId;
			this.api('i/update_home', {
				home: this.I.client_settings.home
			}).then(() => {
				this.I.update();
			});
		};
	</script>
</mk-channel-home-widget>

<mk-channel>
	<p if={ fetching }>読み込み中<mk-ellipsis/></p>
	<div if={ !fetching } ref="posts">
		<p if={ posts.length == 0 }>まだ投稿がありません</p>
		<mk-channel-post each={ post in posts.slice().reverse() } post={ post } form={ parent.refs.form }/>
	</div>
	<mk-channel-form ref="form"/>
	<style>
		:scope
			display block
			background #efefef

			> div
				height calc(100% - 38px)
				overflow auto

			> mk-channel-form
				position absolute
				left 0
				bottom 0

	</style>
	<script>
		import ChannelStream from '../../../common/scripts/channel-stream';

		this.mixin('api');

		this.fetching = true;
		this.channel = null;
		this.posts = [];

		this.on('mount', () => {

		});

		this.on('unmount', () => {
			if (this.connection) {
				this.connection.off('post', this.onPost);
				this.connection.close();
			}
		});

		this.zap = channel => {
			this.update({
				fetching: true,
				channel: channel
			});

			this.api('channels/posts', {
				channel_id: channel.id
			}).then(posts => {
				this.update({
					fetching: false,
					posts: posts
				});

				this.scrollToBottom();

				if (this.connection) {
					this.connection.off('post', this.onPost);
					this.connection.close();
				}
				this.connection = new ChannelStream(this.channel.id);
				this.connection.on('post', this.onPost);
			});
		};

		this.onPost = post => {
			this.posts.unshift(post);
			this.update();
			this.scrollToBottom();
		};

		this.scrollToBottom = () => {
			this.refs.posts.scrollTop = this.refs.posts.scrollHeight;
		};
	</script>
</mk-channel>

<mk-channel-post>
	<header>
		<a class="index" onclick={ reply }>{ post.index }:</a>
		<a class="name" href={ CONFIG.url + '/' + post.user.username }><b>{ post.user.name }</b></a>
		<span>ID:<i>{ post.user.username }</i></span>
	</header>
	<div>
		<a if={ post.reply }>&gt;&gt;{ post.reply.index }</a>
		{ post.text }
		<div class="media" if={ post.media }>
			<virtual each={ file in post.media }>
				<a href={ file.url } target="_blank">
					<img src={ file.url + '?thumbnail&size=512' } alt={ file.name } title={ file.name }/>
				</a>
			</virtual>
		</div>
	</div>
	<style>
		:scope
			display block
			margin 0
			padding 0

			> header
				position -webkit-sticky
				position sticky
				z-index 1
				top 0
				padding 0 0 0 8px
				background rgba(239, 239, 239, 0.9)

				> .index
					margin-right 0.25em
					color #000

				> .name
					margin-right 0.5em
					color #008000

				@media (max-width 600px)
					> mk-time
						&:first-of-type
							display initial

						&:last-of-type
							display none

			> div
				padding 0 0 1em 2em

				> .media
					> a
						display inline-block

						> img
							max-width 100%
							vertical-align bottom

	</style>
	<script>
		this.post = this.opts.post;
		this.form = this.opts.form;

		this.reply = () => {
			this.form.update({
				reply: this.post
			});
		};
	</script>
</mk-channel-post>

<mk-channel-form>
	<p if={ reply }><b>&gt;&gt;{ reply.index }</b> ({ reply.user.name }): <a onclick={ clearReply }>[x]</a></p>
	<input ref="text" disabled={ wait } onkeydown={ onkeydown } placeholder="書いて">
	<style>
		:scope
			display block
			width 100%
			height 38px
			padding 4px
			border-top solid 1px #ddd

			> input
				padding 0 8px
				width 100%
				height 100%
				font-size 14px
				color #55595c
				border solid 1px #dadada
				border-radius 4px

				&:hover
				&:focus
					border-color #aeaeae

	</style>
	<script>
		this.mixin('api');

		this.clearReply = () => {
			this.update({
				reply: null
			});
		};

		this.clear = () => {
			this.clearReply();
			this.refs.text.value = '';
		};

		this.onkeydown = e => {
			if (e.which == 10 || e.which == 13) this.post();
		};

		this.post = () => {
			this.update({
				wait: true
			});

			this.api('posts/create', {
				text: this.refs.text.value,
				reply_id: this.reply ? this.reply.id : undefined,
				channel_id: this.parent.channel.id
			}).then(data => {
				this.clear();
			}).catch(err => {
				alert('失敗した');
			}).then(() => {
				this.update({
					wait: false
				});
			});
		};
	</script>
</mk-channel-form>
