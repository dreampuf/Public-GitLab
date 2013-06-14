module Emails
  module Commits
    def receive_commit_email(project_id, author_id, data)
      project = Project.find(project_id)
      Gitlab::AppLogger.info "#{project.name}, #{author_id}, #{data}"
      user = User.find(author_id)
      user_emails = project.users.map {|u| u.email}
      #puts user_emails
      mail(to: user_emails, subject: subject("[Git][#{project.name}][#{user.name}][#{data[:ref]}]")) do |format|
        format.html { render :text => render_diffs(project.repo, data) }
      end 
    end

    private

    def render_diffs(repository, data)
      compare = Gitlab::Git::Compare.new(repository, data[:before], data[:after])
      ref = data[:ref]
      Haml::Engine.new('
%p.cgray
  Showing #{diffs.count} changed file
.file-stats
  %ul.bordered-list
    - diffs.each_with_index do |diff, i|
      %li
        - if diff.deleted_file
          %span.deleted-file
            %a{href: "#diff-#{i}"}
              %i.icon-minus
              = diff.old_path
        - elsif diff.renamed_file
          %span.renamed-file
            %a{href: "#diff-#{i}"}
              %i.icon-minus
              = diff.old_path
              = "->"
              = diff.new_path
        - elsif diff.new_file
          %span.new-file
            %a{href: "#diff-#{i}"}
              %i.icon-plus
              = diff.new_path
        - else
          %span.edit-file
            %a{href: "#diff-#{i}"}
              %i.icon-adjust
              = diff.new_path
.files
  - diffs.each_with_index do |diff, i|
    - next if diff.diff.empty?
    - file = Gitlab::Git::Blob.new(repository, commit.id, ref, diff.new_path)
    - file = Gitlab::Git::Blob.new(repository, commit.parent_id, ref, diff.old_path) unless file.exists?
    - next unless file.exists?
    .file{id: "diff-#{i}"}
      .header
        - if diff.deleted_file
          %span= diff.old_path

          - if commit.parent_ids.present?
            -#= link_to project_blob_path(@project, tree_join(@commit.parent_id, diff.new_path)), {:class => \'btn btn-tiny pull-right view-file\'} do
            -#  View file @
            -#  %span.commit-short-id= @commit.short_id(6)
        - else
          %span= diff.new_path
          - if diff.a_mode && diff.b_mode && diff.a_mode != diff.b_mode
            %span.file-mode= "#{diff.a_mode} -> #{diff.b_mode}"

          -#= link_to project_blob_path(@project, tree_join(@commit.id, diff.new_path)), {:class => \'btn btn-tiny pull-right view-file\'} do
          -#  View file @
          -#  %span.commit-short-id= @commit.short_id(6)

      .content
        -# Skipp all non non-supported blobs
        - next unless file.respond_to?(\'text?\')
        - if file.text?
          = render "commits/text_file", diff: diff, index: i
        - elsif file.image?
          - old_file = Gitlab::Git::Blob.new(repository, commit.parent_id, ref, diff.old_path) if commit.parent_id
          = render "commits/image", diff: diff, old_file: old_file, file: file, index: i
        - else
          %p.nothing_here_message No preview for this file type
').render({}, {
    "diffs"         => compare.diffs,
    "repository"    => repository,
    "commit"        => compare.commit,
    "commits"       => compare.commits,
    "refs_are_same" => compare.same,
    "ref"           => ref,
})
    end
  end
end
