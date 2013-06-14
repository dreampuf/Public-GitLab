module Emails
  module Commits
    def receive_commit_email(project_id, author_id, data, recipients)
      @project = Project.find(project_id)
      @user = User.find(author_id)
      @data = data
      @repository = @project.repository
      compare = Gitlab::Git::Compare.new(@repository, data[:before], data[:after])
      @diffs = compare.diffs
      @time_now = Time.now
      @commit = compare.commit
      @commits = compare.commits
      @refs_are_same = compare.same
      @ref = data[:ref]

      Gitlab::AppLogger.info "#{@project.name}, #{@user.username}, #{data[:ref]} receive a push"
      simple_ref_name = @ref.split("/")[-1]
      simple_message = @commit ? @commit.message.split("\n")[0] : ""
      subject = "[Git][#{@project.name}:#{simple_ref_name}][#{@user.username}] #{ simple_message }"
      recipients_email = recipients.map{|u| u.email}
      if recipients_email.any?
          mail(to: recipients_email, subject: subject)
      end
    end
  end
end
