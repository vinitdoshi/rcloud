make.oc <- function(fun, name=deparse(substitute(fun))) {
  f <- function(...) try(fun(...), silent=TRUE)
  Rserve:::ocap(f, name)
}

wrap.js.fun <- function(s)
{
  if (!inherits(s, "javascript_function"))
    stop("Can only wrap 'javascript_function's");
  function(...) self.oobMessage(list(s, ...))
}

wrap.all.js.funs <- function(v)
{
  if (inherits(v, 'javascript_function'))
    wrap.js.fun(v)
  else if (is.list(v))
    lapply(v, wrap.all.js.funs)
  else
    v
}

oc.init <- function(...) { ## this is the payload of the OCinit message
  ## remove myself from the global env since my job is done
  if (identical(.GlobalEnv$oc.init, oc.init)) rm(oc.init, envir=.GlobalEnv)

  ## simply send the cap that authenticates and returns supported caps
  make.oc(function(v) {
    if (RC.authenticate(v)) {
      authenticated.ocaps()
    } else {
      unauthenticated.ocaps()
    }
  }, "oc.init")
}

unauthenticated.ocaps <- function()
{
  list(
    # ocaps used by rcloud.js
    rcloud=list(
      authenticated = FALSE,
      anonymous_session_init = make.oc(rcloud.anonymous.session.init),
      prefix_uuid = make.oc(rcloud.prefix.uuid),
      reset_session = make.oc(rcloud.reset.session),
      get_conf_value = make.oc(rcloud.get.conf.value),
      get_notebook = make.oc(rcloud.unauthenticated.get.notebook),
      load_notebook = make.oc(rcloud.unauthenticated.load.notebook),
      install_notebook_stylesheets = make.oc(rcloud.install.notebook.stylesheets),
      
      is_notebook_published = make.oc(rcloud.is.notebook.published),
      
      get_users = make.oc(rcloud.get.users),

      # javascript.R
      setup_js_installer = make.oc(rcloud.setup.js.installer),

      # logging ocaps
      log = list(
        record_cell_execution = make.oc(rcloud.record.cell.execution)
        ),

      # commenting ocaps
      comments = list(
        get_all = make.oc(rcloud.get.comments)
        ),

      # debugging
      debug=list(
        raise=make.oc(function(msg) stop(paste("Forced exception", msg)))
        ),

      # stars
      stars=list(
        star_notebook = make.oc(rcloud.star.notebook), 
        unstar_notebook = make.oc(rcloud.unstar.notebook),
        is_notebook_starred = make.oc(rcloud.is.notebook.starred),
        get_notebook_star_count = make.oc(rcloud.notebook.star.count),
        get_multiple_notebook_star_counts = make.oc(rcloud.multiple.notebook.star.counts),
        get_my_starred_notebooks = make.oc(rcloud.get.my.starred.notebooks)
        ),

      session_cell_eval = make.oc(rcloud.unauthenticated.session.cell.eval)
      )
    )
}

authenticated.ocaps <- function()
{
  basic.ocaps <- unauthenticated.ocaps()
  changes <- list(
    rcloud = list(
      authenticated = TRUE,
      session_init = make.oc(rcloud.session.init),
      session_markdown_eval = make.oc(session.markdown.eval),
      load_user_config = make.oc(rcloud.load.user.config),
      save_user_config = make.oc(rcloud.save.user.config),
      load_multiple_user_configs = make.oc(rcloud.load.multiple.user.configs),
      search = make.oc(rcloud.search),
      get_notebook = make.oc(rcloud.get.notebook),
      load_notebook = make.oc(rcloud.load.notebook),
      update_notebook = make.oc(rcloud.update.notebook),
      create_notebook = make.oc(rcloud.create.notebook),
      rename_notebook = make.oc(rcloud.rename.notebook),
      publish_notebook = make.oc(rcloud.publish.notebook),
      unpublish_notebook = make.oc(rcloud.unpublish.notebook),
      fork_notebook = make.oc(rcloud.fork.notebook),
      port_notebooks = make.oc(rcloud.port.notebooks),
      call_notebook = make.oc(rcloud.call.notebook),
      get_completions = make.oc(rcloud.get.completions),

      # This will cause bugs, because some notebooks want a
      # call_fastrweb_notebook...
      call_fastrweb_notebook = make.oc(rcloud.call.FastRWeb.notebook),
      
      # file upload ocaps
      file_upload = list(
        create = make.oc(rcloud.upload.create.file),
        write = make.oc(rcloud.upload.write.file),
        close = make.oc(rcloud.upload.close.file),
        upload_path = make.oc(rcloud.upload.path)
        ),
      notebook_upload = make.oc(rcloud.upload.to.notebook),
      
      # commenting ocaps
      comments = list(
        post = make.oc(rcloud.post.comment)
        )
           
      )
  )
  modifyList(basic.ocaps, changes)
}
