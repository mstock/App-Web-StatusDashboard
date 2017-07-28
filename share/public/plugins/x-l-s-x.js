(function () {
	'use strict';

	angular.module('StatusDashboard').directive('xlsx', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.items = [];
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						scope.sheets = newValue.sheets;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/x-l-s-x.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle',
					maxColumns:    '@maxColumns',
					maxRows:       '@maxRows'
				}
			}
		}
	]);
}());
