use strict;
use warnings;
use File::Glob 'bsd_glob';

sub runcmds {
  my ($curve, $cmds) = @_;
  for (split /\n/, $cmds) {
    s/^\s*(.*?)\s*$/$1/;
    warn "##$curve## >$_<\n";
    my $rv = system($_);
    die "ERROR (curve = $curve, rv = $rv)\n" if $rv;
  }
}

sub doit {
  my $curve = shift;
  ### sign openssl > cryptx
  runcmds $curve, <<'MARKER';
    openssl dgst -sha1 -sign test_eckey.priv.pem -out test_input.sha1-ec.sig test_input.data
MARKER

  {
   use Crypt::PK::ECC;
   use Crypt::Digest 'digest_file';
   use Crypt::Misc 'read_rawfile';

   my $pkec = Crypt::PK::ECC->new("test_eckey.pub.pem");
   my $signature = read_rawfile("test_input.sha1-ec.sig");
   my $valid = $pkec->verify_hash($signature, digest_file("SHA1", "test_input.data"), "SHA1");
   print $valid ? "SUCCESS" : "FAILURE";
  }

  ### sign cryptx > openssl
  {
   use Crypt::PK::ECC;
   use Crypt::Digest 'digest_file';
   use Crypt::Misc 'write_rawfile';

   my $pkec = Crypt::PK::ECC->new("test_eckey.priv.pem");
   my $signature = $pkec->sign_hash(digest_file("SHA1", "test_input.data"), "SHA1");
   write_rawfile("test_input.sha1-ec.sig", $signature);
  }

  runcmds $curve, <<'MARKER';
   openssl dgst -sha1 -verify test_eckey.pub.pem -signature test_input.sha1-ec.sig test_input.data
MARKER
}

### MAIN ###

my $curve;
write_rawfile("test_input.data", "test-file-content");

# list supported curves: openssl ecparam -list_curves | grep "prime field"

for $curve (qw/brainpoolp160r1 brainpoolp192r1 brainpoolp224r1 brainpoolp256r1 brainpoolp320r1 brainpoolp384r1 brainpoolp512r1
               brainpoolp160t1 brainpoolp192t1 brainpoolp224t1 brainpoolp256t1 brainpoolp320t1 brainpoolp384t1 brainpoolp512t1
               wap-wsg-idm-ecid-wtls8 wap-wsg-idm-ecid-wtls9
               wap-wsg-idm-ecid-wtls6 wap-wsg-idm-ecid-wtls7 wap-wsg-idm-ecid-wtls12
               secp112r1 secp112r2 secp128r1 secp128r2 secp160k1 secp160r1 secp160r2 secp192k1
               secp192r1 secp224k1 secp224r1 secp256k1 secp256r1 secp384r1 secp521r1
               prime192v1 prime192v2 prime192v3 prime239v1 prime239v2 prime239v3 prime256v1
               nistp192 nistp224 nistp256 nistp384 nistp521/) {
  ### keys generated by cryptx
  {
   use Crypt::PK::ECC;
   use Crypt::Misc 'write_rawfile';

   my $pkec = Crypt::PK::ECC->new;
   $pkec->generate_key($curve);
   write_rawfile("test_eckey.pub.der",  $pkec->export_key_der('public'));
   write_rawfile("test_eckey.priv.der", $pkec->export_key_der('private'));
   write_rawfile("test_eckey.pub.pem",  $pkec->export_key_pem('public'));
   write_rawfile("test_eckey.priv.pem", $pkec->export_key_pem('private'));
   write_rawfile("test_eckey-passwd.priv.pem", $pkec->export_key_pem('private', 'secret'));
   #short
   write_rawfile("test_eckey.pubs.der",  $pkec->export_key_der('public_short'));
   write_rawfile("test_eckey.privs.der", $pkec->export_key_der('private_short'));
   write_rawfile("test_eckey.pubs.pem",  $pkec->export_key_pem('public_short'));
   write_rawfile("test_eckey.privs.pem", $pkec->export_key_pem('private_short'));
   write_rawfile("test_eckey-passwd.privs.pem", $pkec->export_key_pem('private_short', 'secret'));
  }

  runcmds "$curve/A", <<'MARKER';
   openssl ec -in test_eckey.priv.der -text -inform der
   openssl ec -in test_eckey.priv.pem -text
   openssl ec -in test_eckey-passwd.priv.pem -text -inform pem -passin pass:secret
   openssl ec -in test_eckey.pub.der -pubin -text -inform der
   openssl ec -in test_eckey.pub.pem -pubin -text
   openssl ec -in test_eckey.privs.der -text -inform der
   openssl ec -in test_eckey.privs.pem -text
   openssl ec -in test_eckey-passwd.privs.pem -text -inform pem -passin pass:secret
   openssl ec -in test_eckey.pubs.der -pubin -text -inform der
   openssl ec -in test_eckey.pubs.pem -pubin -text
MARKER

  doit("$curve/A");
}

# openssl ecparam -list_curves
for my $curve (qw/secp112r1 secp112r2 secp128r1 secp128r2 secp160k1 secp160r1 secp160r2 secp192k1
                  secp224k1 secp224r1 secp256k1 secp384r1 secp521r1
                  prime192v1 prime192v2 prime192v3 prime239v1 prime239v2 prime239v3 prime256v1
                  brainpoolP160r1 brainpoolP160t1 brainpoolP192r1 brainpoolP192t1 brainpoolP224r1
                  brainpoolP224t1 brainpoolP256r1 brainpoolP256t1 brainpoolP320r1 brainpoolP320t1
                  brainpoolP384r1 brainpoolP384t1 brainpoolP512r1 brainpoolP512t1/) {
  ### keys generated by openssl
  runcmds "$curve/B", <<"MARKER";
   openssl ecparam -param_enc explicit -name $curve -genkey -out test_eckey.priv.pem
   openssl ec -param_enc explicit -in test_eckey.priv.pem -out test_eckey.pub.pem -pubout
   openssl ec -param_enc explicit -in test_eckey.priv.pem -out test_eckey.priv.der -outform der
   openssl ec -param_enc explicit -in test_eckey.priv.pem -out test_eckey.pub.der -outform der -pubout
   openssl ec -param_enc explicit -in test_eckey.priv.pem -out test_eckey.privc.der -outform der -conv_form compressed
   openssl ec -param_enc explicit -in test_eckey.priv.pem -out test_eckey.pubc.der -outform der -pubout -conv_form compressed
   openssl ec -param_enc explicit -in test_eckey.priv.pem -passout pass:secret -des3 -out test_eckey-passwd.priv.pem
MARKER

  {
   use Crypt::PK::ECC;

   my $pkec = Crypt::PK::ECC->new;
   warn("> gonna import: test_eckey.pub.der\n");                  $pkec->import_key("test_eckey.pub.der");
   warn("> gonna import: test_eckey.pubc.der\n");                 $pkec->import_key("test_eckey.pubc.der");
   warn("> gonna import: test_eckey.priv.der\n");                 $pkec->import_key("test_eckey.priv.der");
   warn("> gonna import: test_eckey.privc.der\n");                $pkec->import_key("test_eckey.privc.der");
   warn("> gonna import: test_eckey.pub.pem\n");                  $pkec->import_key("test_eckey.pub.pem");
   warn("> gonna import: test_eckey.priv.pem\n");                 $pkec->import_key("test_eckey.priv.pem");
   warn("> gonna import: test_eckey-passwd.priv.pem + secret\n"); $pkec->import_key("test_eckey-passwd.priv.pem", "secret");
  }

  doit("$curve/B");
}

warn "\nSUCCESS\n";
unlink $_ for (bsd_glob("test_*.der"), bsd_glob("test_*.pem"), bsd_glob("test_*.sig"), bsd_glob("test_*.data"));