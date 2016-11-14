#!perl

requires 'perl', '5.8.5';

requires 'strict';
requires 'warnings';
requires 'threads::shared';
requires 'Collectd';
requires 'Net::Lumberjack';
requires 'Sys::Hostname';

on 'test' => sub {
  requires 'Test::More';
  requires 'File::Find';
};

on 'develop' => sub {
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::MetaProvides::Package';
  requires 'Dist::Zilla::Plugin::ChangelogFromGit';
  requires 'Dist::Zilla::Plugin::Git::NextVersion';
  requires 'Dist::Zilla::Plugin::OurPkgVersion';
  requires 'Dist::Zilla::Plugin::PodSyntaxTests';
  requires 'Dist::Zilla::Plugin::PodWeaver';
  requires 'Dist::Zilla::Plugin::Prereqs';
  requires 'Dist::Zilla::Plugin::Test::Perl::Critic';
  requires 'Dist::Zilla::PluginBundle::Basic';
  requires 'Dist::Zilla::PluginBundle::Git';
  requires 'Software::License::GPL_2';
};

