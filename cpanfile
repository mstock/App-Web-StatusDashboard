requires "Carp" => "0";
requires "Class::Load" => "0";
requires "Data::ICal::DateTime" => "0";
requires "DateTime" => "0";
requires "Encode" => "0";
requires "File::ShareDir" => "0";
requires "File::Spec::Functions" => "0";
requires "File::Temp" => "0";
requires "HTTP::AcceptLanguage" => "0";
requires "List::MoreUtils" => "0";
requires "List::Util" => "0";
requires "Log::Any" => "0";
requires "Log::Any::Adapter" => "0";
requires "Log::Any::Adapter::MojoLog" => "0";
requires "MRO::Compat" => "0";
requires "Mojo::Base" => "0";
requires "Mojo::EventEmitter" => "0";
requires "Mojo::IOLoop" => "0";
requires "Mojo::IOLoop::ForkCall" => "0";
requires "Mojo::URL" => "0";
requires "Mojo::UserAgent" => "0";
requires "Mojo::Util" => "0";
requires "Mojolicious::Commands" => "0";
requires "Path::Tiny" => "0";
requires "Scalar::Util" => "0";
requires "Set::Tiny" => "0";
requires "Spreadsheet::XLSX" => "0";
requires "Test::Deep::NoTest" => "0";
requires "XML::Feed" => "0";
requires "lib" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "File::Find" => "0";
  requires "Test::Mojo" => "0";
  requires "Test::More" => "0.88";
};

on 'configure' => sub {
  requires "Module::Build" => "0.3601";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "version" => "0.9901";
};
