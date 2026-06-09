#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <flutter_linux/fl_application.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  FlApplication parent_instance;
};

G_DEFINE_TYPE(MyApplication, my_application, fl_application_get_type())

static void my_application_activate(GApplication *application) {
  fl_application_activate(FL_APPLICATION(application));
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
}

static void my_application_init(MyApplication *self) {}

MyApplication *my_application_new() {
  return MY_APPLICATION(
    g_object_new(my_application_get_type(), "application-id",
                 "com.ai.image.editor", nullptr));
}
