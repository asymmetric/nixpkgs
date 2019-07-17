{ lib
, buildPythonPackage
, fetchPypi
, pytest
, setuptools_scm
, six
}:

buildPythonPackage rec {
  pname = "testinfra";
  version = "3.0.5";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1gqw0m95ywr8jl5hwmxm8ngq1hwlih8pwb3s6a5fb6c5gnz9daqk";
  };

  nativeBuildInputs = [ pytest setuptools_scm six ];

  meta = with lib; {
    description = "Test your infrastructures";
    homepage = "https://testinfra.readthedocs.io/en/latest/";
    license = linceses.asl20;
    maintainers = [ maintainers.asymmetric ];
  };
}
