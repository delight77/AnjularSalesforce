module.exports = {
    deploy: {
        username:       'gavrish@codeswat.com',
        password:       'delight2045376',
        login_url:      'https://login.salesforce.com',
        api_version:    36.0,
        timeout:        120000,
        poll_interval:  5000,
    },

    visualforce: {
        template: 'index.page.html',
        page: 'AngularApp',
        controller: 'AngularAppController'
    },

    resources: {
        app_resource_name: 'AngularApp',
        node_module_resource_name: 'NodeModules',
    },

    options: {
        
    }
}