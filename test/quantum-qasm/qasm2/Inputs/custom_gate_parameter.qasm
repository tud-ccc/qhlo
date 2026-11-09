OPENQASM 2.0;
gate rotate(theta) q {
  U(theta, 0, 0) q;
}
qreg q[1];
rotate(0.5) q[0];
