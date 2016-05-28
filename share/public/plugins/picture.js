(function () {
	'use strict';

	angular.module('StatusDashboard').directive('picture', [
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
						scope.data = newValue.data;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/picture.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle'
				}
			}
		}
	]);
}());
