package com.careerbridge.careerbridge

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth so the
// system biometric prompt can attach to a FragmentActivity host. This is the only
// change the biometric feature needs on the Android side.
class MainActivity : FlutterFragmentActivity()
