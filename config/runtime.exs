import Config

# Resdayn is a library -- it is never deployed on its own, and when it is used
# as a path dependency this file is not loaded at all (only the top-level
# application's runtime.exs is). Production configuration for Resdayn.Repo
# therefore lives in the host application, in library/config/runtime.exs.
