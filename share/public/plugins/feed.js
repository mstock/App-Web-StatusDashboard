(function () {
	'use strict';

	angular.module('StatusDashboard').directive('feed', [
		'statusService',
		function (statusService, moment) {
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
						scope.items = newValue;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/feed.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle',
					dateFormat:    '@dateFormat',
					count:         '@count'
				}
			}
		}
	]);
}());
